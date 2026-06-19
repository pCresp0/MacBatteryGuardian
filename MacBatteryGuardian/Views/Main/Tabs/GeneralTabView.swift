// GeneralTabView.swift
// Pestaña General: resumen ejecutivo del estado del sistema.

import SwiftUI

struct GeneralTabView: View {

    @EnvironmentObject private var store: ViewModelStore
    @EnvironmentObject private var monitor: MonitoringManager

    var body: some View {
        let battery = store.popover
        let health  = store.health
        let cpu     = store.cpu
        let memory  = store.memory

        VStack(spacing: 0) {
            glassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        batteryCard(battery: battery).generalGridCell()
                        healthCard(health: health).generalGridCell()
                    }
                    HStack(alignment: .top, spacing: 12) {
                        cpuCard(cpu: cpu).generalGridCell()
                        memoryCard(memory: memory).generalGridCell()
                    }
                    HStack(alignment: .top, spacing: 12) {
                        consumptionCard(battery: battery).generalGridCell()
                        powerModeCard.generalGridCell()
                    }
                }
            }
            .padding(16)

            if !health.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recomendaciones")
                        .font(.headline)
                        .padding(.horizontal, 20)

                    ForEach(health.recommendations.prefix(3)) { rec in
                        RecommendationCardView(recommendation: rec)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Tarjetas

    private func batteryCard(battery: PopoverViewModel) -> some View {
        MetricCardView(title: "Batería", icon: "battery.100", iconColor: .green, destinationTab: .battery) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(battery.batteryPercentage)%")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(battery.batteryColor)

                BatteryHorizontalBarView(
                    percentage: battery.batteryPercentage,
                    isCharging: battery.isCharging,
                    isPluggedIn: battery.isPluggedIn
                )

                if let chargeLabel = battery.chargeCompleteFormatted {
                    Label(chargeLabel, systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if battery.isCharging {
                    Label("Cargando — calculando tiempo…", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if battery.isPluggedIn {
                    Label("Conectado", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(battery.autonomyFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func healthCard(health: HealthViewModel) -> some View {
        MetricCardView(title: "Salud del Mac", icon: "heart.fill", iconColor: health.scoreColor, destinationTab: .health) {
            VStack(alignment: .leading, spacing: 8) {
                HealthScoreBarView(
                    score: health.score,
                    color: health.scoreColor,
                    levelTitle: health.level.localizedTitle
                )
                if health.recommendations.count > 0 {
                    Text("\(health.recommendations.count) recomendaciones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func cpuCard(cpu: CPUViewModel) -> some View {
        MetricCardView(title: "CPU", icon: "cpu", iconColor: .blue, destinationTab: .cpu) {
            VStack(alignment: .leading, spacing: 8) {
                Text(cpu.totalUsage)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                TimelineChartView(
                    samples: cpu.cpuTimeline,
                    color: .blue,
                    yMin: 0,
                    yMax: 100,
                    style: .summary
                )
            }
        }
    }

    private func memoryCard(memory: MemoryViewModel) -> some View {
        MetricCardView(title: "Memoria RAM", icon: "memorychip", iconColor: .purple, destinationTab: .memory) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(memory.usedFormatted)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                    Text("/ \(memory.totalFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: memory.usedPercent, total: 100)
                    .tint(memory.pressureColor)

                Text("Presión: \(memory.pressureLevel.localizedDescription)")
                    .font(.caption)
                    .foregroundStyle(memory.pressureColor)

                TimelineChartView(
                    samples: memory.memoryTimeline,
                    color: .purple,
                    yMin: 0,
                    yMax: 100,
                    style: .summary
                )
            }
        }
    }

    private func consumptionCard(battery: PopoverViewModel) -> some View {
        MetricCardView(title: "Consumo energético", icon: "flame.fill", iconColor: battery.alertColor, destinationTab: .battery) {
            VStack(alignment: .leading, spacing: 4) {
                Text(battery.consumptionRate == "–" ? "Calculando…" : battery.consumptionRate)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(battery.consumptionRate == "–" ? .secondary : battery.alertColor)
                Text(
                    battery.consumptionRate == "–"
                        ? "Se necesitan al menos 5 min a batería para estimar el consumo."
                        : battery.alertState.localizedDescription
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var powerModeCard: some View {
        MetricCardView(
            title: "Modo de energía",
            icon: "bolt.circle",
            iconColor: .yellow,
            destinationTab: .settings
        ) {
            HStack(spacing: 6) {
                Image(systemName: monitor.powerModeState.mode.sfSymbolName)
                    .font(.body)
                    .foregroundStyle(
                        monitor.powerModeState.mode == .lowPower ? Color.lowPowerMode : .secondary
                    )
                Text(monitor.powerModeState.mode.localizedTitle)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        } footer: {
            Button(monitor.powerModeState.mode == .lowPower ? "Desactivar modo bajo consumo" : "Activar modo bajo consumo") {
                Task {
                    let enable = monitor.powerModeState.mode != .lowPower
                    await monitor.setLowPowerMode(enabled: enable)
                }
            }
            .frame(maxWidth: .infinity)
            .controlSize(.small)
            .liquidGlassBorderedButton()
        }
    }
}

// MARK: - Grid General (ancho compartido, altura según contenido)

private extension View {
    func generalGridCell() -> some View {
        frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
