// PopoverView.swift
// Panel flotante del icono de barra de menú.
// Auto-sizing, totalmente auto-explicativo con ⓘ toggles e iconografía clara.

import SwiftUI
import AppKit

struct PopoverView: View {

    @EnvironmentObject private var store: ViewModelStore
    @EnvironmentObject private var monitor: MonitoringManager

    private enum Layout {
        static let horizontalInset: CGFloat = 12
        static let metricSpacing: CGFloat = 8
    }

    // Controlan qué descripciones están abiertas
    @State private var showBatteryInfo  = false
    @State private var showThermalInfo  = false
    @State private var showLPMInfo      = false
    @State private var isRefreshing     = false

    var body: some View {
        let vm = store.popover
        VStack(spacing: 0) {
            headerSection(vm: vm)
            liquidGlassSectionDivider()
            batterySection(vm: vm)
            liquidGlassSectionDivider()
            systemSection(vm: vm)
            if !vm.topProcesses.isEmpty {
                liquidGlassSectionDivider()
                processesSection(vm: vm)
            }
            liquidGlassSectionDivider()
            footerSection(vm: vm)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 320)
        .popoverChromeBackground()
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(vm: PopoverViewModel) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacBatteryGuardian")
                    .font(.headline)
                Text(relativeUpdateText())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                guard !isRefreshing else { return }
                isRefreshing = true
                Task {
                    await monitor.refreshNow()
                    isRefreshing = false
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(
                        isRefreshing
                            ? .linear(duration: 0.7).repeatForever(autoreverses: false)
                            : .default,
                        value: isRefreshing
                    )
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)
            .help("Actualizar datos ahora (batería, CPU, temperatura…)")

            lpmBadge(vm: vm)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func relativeUpdateText() -> String {
        guard let date = monitor.lastUpdateDate else { return "Iniciando…" }
        let secs = Int(-date.timeIntervalSinceNow)
        if secs < 5  { return "Actualizado ahora" }
        if secs < 60 { return "Actualizado hace \(secs)s" }
        return "Actualizado hace \(secs / 60) min"
    }

    // MARK: - Badge Modo Bajo Consumo / Normal

    @ViewBuilder
    private func lpmBadge(vm: PopoverViewModel) -> some View {
        let isLPM = monitor.powerModeState.mode == .lowPower
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: isLPM ? "bolt.fill" : "bolt.fill")
                    .font(.caption2)
                Text(isLPM ? "Bajo Consumo" : "Normal")
                    .font(.caption).fontWeight(.medium)
            }
            .foregroundStyle(isLPM ? Color.lowPowerMode : .secondary)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .liquidGlassInset(cornerRadius: LiquidGlassTokens.cellRadius)

            if showLPMInfo {
                Text(isLPM
                     ? "El Mac reduce rendimiento y brillo para ahorrar batería."
                     : "El Mac trabaja a pleno rendimiento.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 160)
            }
        }
        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { showLPMInfo.toggle() } }
        .help(isLPM
              ? "Modo Bajo Consumo activo — toca para más info"
              : "Modo Normal — toca para más info")
    }

    // MARK: - Batería

    @ViewBuilder
    private func batterySection(vm: PopoverViewModel) -> some View {
        let isLPM = monitor.powerModeState.mode == .lowPower
        let accent = isLPM ? Color.lowPowerMode : vm.batteryColor

        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Button {
                    MainWindowNavigation.open(tab: .battery)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        BatteryArcView(
                            percentage: vm.batteryPercentage,
                            isCharging: vm.isCharging,
                            isPluggedIn: vm.isPluggedIn,
                            hasInternalBattery: vm.hasInternalBattery,
                            isLowPowerMode: isLPM
                        )
                        .frame(width: 52, height: 52)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                if vm.batteryPercentage == 0 && !vm.hasRealData {
                                    Text("Leyendo…")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                } else if vm.hasInternalBattery {
                                    Text("\(vm.batteryPercentage)%")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundStyle(accent)
                                    Text(isLPM ? "Bajo consumo" : chargeStateTag(vm))
                                        .font(.caption2).foregroundStyle(isLPM ? Color.lowPowerMode : .secondary)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(
                                            (isLPM ? Color.lowPowerMode : Color.secondary).opacity(0.12),
                                            in: Capsule()
                                        )
                                } else if vm.isPluggedIn {
                                    Text("Conectado")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundStyle(.green)
                                    Text("A la corriente")
                                        .font(.caption2).foregroundStyle(.secondary)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(Color.green.opacity(0.12), in: Capsule())
                                } else {
                                    Text("Sin batería")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if vm.hasInternalBattery {
                                if vm.hasRealData {
                                    chargingTimeLine(vm, accent: accent)
                                } else {
                                    Label("Calculando autonomía…", systemImage: "clock")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            } else if vm.isPluggedIn {
                                Label("Alimentado por corriente alterna", systemImage: "bolt.fill")
                                    .font(.caption).foregroundStyle(.green)
                            }

                            if !vm.isPluggedIn, vm.averageConsumptionRate != "–" {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2).foregroundStyle(vm.alertColor)
                                    Text(vm.averageConsumptionRate)
                                        .font(.caption).foregroundStyle(vm.alertColor)
                                }
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(SystemMetricCellButtonStyle(accent: accent))
                .help("Ver detalle de batería en el análisis completo")

                infoButton(isOpen: showBatteryInfo) {
                    withAnimation(.easeInOut(duration: 0.2)) { showBatteryInfo.toggle() }
                }
                .padding(10)
            }

            if showBatteryInfo {
                infoBox("""
                El porcentaje es el nivel actual. El consumo medio (%/h) es la media de varias \
                ventanas de tiempo. La hora de agotamiento estima cuándo llegaría a 0 % si no \
                enchufas el cargador, en formato 24 horas.
                """)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, Layout.horizontalInset)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func chargingTimeLine(_ vm: PopoverViewModel, accent: Color) -> some View {
        if vm.isCharging, let label = vm.chargeCompleteFormatted {
            Label(label, systemImage: "bolt.fill")
                .font(.caption).foregroundStyle(.green)
                .help("Tiempo estimado para completar la carga al ritmo actual")
        } else if vm.isCharging {
            Label("Cargando — calculando tiempo…", systemImage: "bolt.fill")
                .font(.caption).foregroundStyle(.green)
        } else if vm.isPluggedIn {
            if vm.isBatteryFull {
                Label("Conectado — batería completa", systemImage: "bolt.fill")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Label("Conectado al cargador — carga en pausa", systemImage: "bolt.fill")
                    .font(.caption).foregroundStyle(.secondary)
                    .help("Enchufado pero sin carga activa ahora (p. ej. carga optimizada o límite térmico)")
            }
        } else if let label = vm.estimatedDepletionLabel {
            Label("Se agotaría \(label)", systemImage: "clock")
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(accent)
                .help("Según consumo medio (\(vm.averageConsumptionRate))")
        } else if let mins = vm.minutesToEmpty {
            Label("Quedan ≈ \(Date.batteryMinutesFormatted(mins))", systemImage: "clock")
                .font(.caption).foregroundStyle(.secondary)
                .help("Tiempo estimado según el consumo actual. Varía si cambias lo que haces")
        } else {
            Label("Calculando autonomía…", systemImage: "clock")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Sistema (CPU · RAM · Temperatura)

    @ViewBuilder
    private func systemSection(vm: PopoverViewModel) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Layout.metricSpacing) {
                systemCell(
                    icon: "cpu", color: .blue,
                    value: vm.cpuUsage,
                    label: "CPU",
                    detail: cpuDetail(vm.cpuUsage),
                    tab: .cpu,
                    helpText: "Ver detalle de CPU en el análisis completo"
                )
                systemCell(
                    icon: "memorychip", color: .purple,
                    value: vm.memoryUsage,
                    label: "RAM",
                    detail: ramDetail(vm.memoryUsage),
                    tab: .memory,
                    helpText: "Ver detalle de memoria en el análisis completo"
                )
            }
            .padding(.horizontal, Layout.horizontalInset)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider().padding(.horizontal, Layout.horizontalInset)

            VStack(spacing: 0) {
                ThermalGaugeView(
                    thermalState: vm.thermalState,
                    reading: vm.thermalReading
                )
                .padding(.horizontal, Layout.horizontalInset)
                .padding(.vertical, 10)

                if showThermalInfo {
                    infoBox(thermalInfoText(vm.thermalState))
                        .padding(.horizontal, Layout.horizontalInset)
                        .padding(.bottom, 8)
                }
            }
            .overlay(alignment: .topTrailing) {
                infoButton(isOpen: showThermalInfo) {
                    withAnimation(.easeInOut(duration: 0.2)) { showThermalInfo.toggle() }
                }
                .padding(.top, 10)
                .padding(.trailing, Layout.horizontalInset)
            }
        }
    }

    @ViewBuilder
    private func systemCell(
        icon: String, color: Color,
        value: String, label: String, detail: String,
        tab: AppTab,
        helpText: String
    ) -> some View {
        Button {
            MainWindowNavigation.open(tab: tab)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 14))
                Text(value == "–" ? "Midiendo…" : value)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(value == "–" ? .secondary : .primary)
                Text(label)
                    .font(.caption2).foregroundStyle(.secondary)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 9))
                        .foregroundStyle(color.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(SystemMetricCellButtonStyle(accent: color))
        .help(helpText)
    }

    // MARK: - Procesos

    @ViewBuilder
    private func processesSection(vm: PopoverViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Mayor consumo energético", systemImage: "bolt.slash")
                    .font(.caption).fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "info.circle")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.top, 8)
            .help("Apps ordenadas por consumo de CPU+energía. Las primeras son las que más reducen la autonomía de la batería")

            ForEach(vm.topProcesses.prefix(3)) { process in
                ProcessRowView(process: process, compact: true)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Footer

    @ViewBuilder
    private func footerSection(vm: PopoverViewModel) -> some View {
        VStack(spacing: 6) {
            // Actualización e intervalo
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 9)).foregroundStyle(.tertiary)
                Text("Auto cada \(intervalLabel) · bajo consumo energético")
                    .font(.system(size: 9)).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)

            Divider().padding(.horizontal, 8)

            HStack {
                Button("Ver análisis completo →") {
                    MainWindowNavigation.open(tab: .general)
                }
                .buttonStyle(.plain).font(.caption)
                .foregroundStyle(Color.accentColor)
                .help("Historial, ajustes, análisis detallado de consumo por app")

                Spacer()

                lpmToggleButton(vm: vm)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    @ViewBuilder
    private func lpmToggleButton(vm: PopoverViewModel) -> some View {
        let isLPM = monitor.powerModeState.mode == .lowPower
        Button(action: {
            Task { await monitor.setLowPowerMode(enabled: !isLPM) }
        }) {
            Label(
                isLPM ? "Desactivar modo bajo consumo" : "Activar modo bajo consumo",
                systemImage: isLPM ? "bolt.fill" : "bolt"
            )
            .font(.caption)
            .labelStyle(.titleAndIcon)
        }
        .buttonStyle(CompactPopoverButtonStyle(isActive: isLPM))
        .help(isLPM
              ? "Desactiva el Modo Bajo Consumo y vuelve al rendimiento normal"
              : "Activa el Modo Bajo Consumo: reduce brillo y procesos en segundo plano para maximizar la batería")
    }

    // MARK: - Componentes reutilizables

    @ViewBuilder
    private func infoButton(isOpen: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: isOpen ? "xmark.circle.fill" : "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(isOpen ? Color.secondary : Color.secondary.opacity(0.6))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func infoBox(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassInset(cornerRadius: LiquidGlassTokens.cellRadius)
    }

    // MARK: - Helpers de texto

    private func chargeStateTag(_ vm: PopoverViewModel) -> String {
        if vm.isCharging { return "Cargando" }
        if vm.isPluggedIn {
            if vm.isBatteryFull { return "Completa" }
            return "Al cargador"
        }
        if vm.batteryPercentage > 95 { return "Llena" }
        return "Descargando"
    }

    private func alertLabel(_ state: ConsumptionAlertState) -> String {
        switch state {
        case .stable:   return "normal"
        case .elevated: return "elevado"
        case .warning:  return "alto"
        case .severe:   return "muy alto"
        case .critical: return "crítico ⚠"
        }
    }

    private func cpuDetail(_ usage: String) -> String {
        guard let val = Double(usage.replacingOccurrences(of: "%", with: "")) else { return "" }
        if val < 30 { return "Bajo" }
        if val < 60 { return "Moderado" }
        if val < 80 { return "Elevado" }
        return "Muy alto"
    }

    private func ramDetail(_ usage: String) -> String {
        guard let val = Double(usage.replacingOccurrences(of: "%", with: "")) else { return "" }
        if val < 60 { return "Holgada" }
        if val < 80 { return "Normal" }
        if val < 90 { return "Ajustada" }
        return "Presión alta"
    }

    private func thermalInfoText(_ state: SystemThermalState) -> String {
        switch state {
        case .nominal:
            return "Temperatura normal. El Mac trabaja a pleno rendimiento sin ninguna restricción."
        case .fair:
            return "Temperatura algo elevada. El Mac puede reducir levemente la velocidad para estabilizarse."
        case .serious:
            return "Temperatura alta. macOS está limitando la CPU para enfriar el equipo. Cierra las apps más pesadas."
        case .critical:
            return "Temperatura crítica. El Mac aplica throttling total para proteger los componentes. Déjalo enfriar."
        }
    }

    private var intervalLabel: String {
        let secs = SettingsRepository.shared.monitoringIntervalSeconds
        if secs < 120 { return "\(secs) s" }
        return "\(secs / 60) min"
    }
}

// MARK: - Celda CPU/RAM clicable

private struct SystemMetricCellButtonStyle: ButtonStyle {
    var accent: Color

    func makeBody(configuration: Configuration) -> some View {
        SystemMetricCellButtonBody(configuration: configuration, accent: accent)
    }
}

private struct SystemMetricCellButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let accent: Color
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .selectableCellHighlight(
                accent: accent,
                isHovered: isHovered,
                isPressed: configuration.isPressed
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Botón compacto del popover (hover + pulsación)

private struct CompactPopoverButtonStyle: ButtonStyle {
    var isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        CompactPopoverButtonBody(configuration: configuration, isActive: isActive)
    }
}

private struct CompactPopoverButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let isActive: Bool
    @State private var isHovered = false

    private var accent: Color {
        isActive ? .lowPowerMode : .secondary
    }

    var body: some View {
        configuration.label
            .fontWeight(isActive ? .medium : .regular)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .selectableCellHighlight(
                accent: accent,
                isHovered: isHovered,
                isPressed: configuration.isPressed,
                cornerRadius: 6
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }

    private var foregroundColor: Color {
        if isActive { return .lowPowerMode }
        return isHovered ? .primary : .secondary
    }
}

// MARK: - Notification

extension Notification.Name {
    static let openMainWindow = Notification.Name("com.macbatteryguardian.openMainWindow")
}
