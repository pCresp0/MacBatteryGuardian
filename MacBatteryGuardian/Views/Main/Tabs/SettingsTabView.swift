// SettingsTabView.swift
// Pestaña de Configuración: todos los ajustes de la app agrupados por categoría.

import SwiftUI

struct SettingsTabView: View {

    @EnvironmentObject private var vm: SettingsViewModel
    @State private var showResetAlert = false

    var body: some View {
        Form {

            // MARK: - General
            Section("General") {
                settingsToggle(
                    "Iniciar al arrancar el sistema",
                    isOn: $vm.launchAtLogin,
                    help: "Registra MacBatteryGuardian para que se abra sola al iniciar sesión. "
                        + "Permanece en la barra de menú; no aparece en el Dock."
                )
                settingsToggle(
                    "Mostrar porcentaje en la barra de menú",
                    isOn: $vm.showPercentageInMenuBar,
                    help: "Añade el nivel actual de batería (p. ej. 72 %) junto al icono de la app "
                        + "en la barra superior."
                )
                settingsToggle(
                    "Mostrar consumo medio (%/h) en la barra de menú",
                    isOn: $vm.showConsumptionRateInMenuBar,
                    help: "Muestra en la barra superior cuánta batería consumes de media por hora. "
                        + "Es la media de las ventanas de 15 min, 30 min, 1 h y 3 h que ya tengan datos "
                        + "(no solo la última hora). El color indica el estado: verde normal, amarillo/naranja "
                        + "elevado, rojo muy alto. Solo en batería; desaparece al enchufar."
                )
            }

            // MARK: - Monitorización
            Section("Monitorización") {
                settingsPickerRow(
                    "Intervalo de monitorización",
                    help: "Frecuencia con la que la app lee batería, CPU y memoria. "
                        + "Intervalos más cortos rellenan antes las gráficas; los largos ahorran recursos."
                ) {
                    Picker("", selection: $vm.monitoringIntervalSeconds) {
                        Text("1 minuto").tag(60)
                        Text("2 minutos").tag(120)
                        Text("5 minutos (recomendado)").tag(300)
                        Text("10 minutos").tag(600)
                        Text("15 minutos").tag(900)
                    }
                }
            }

            // MARK: - Notificaciones
            Section("Notificaciones") {
                settingsToggle(
                    "Activar notificaciones",
                    isOn: $vm.notificationsEnabled,
                    help: "Muestra avisos del sistema cuando el consumo es anormal, hay un pico sostenido "
                        + "o la app activa el Modo Bajo Consumo automáticamente."
                )
                if vm.notificationsEnabled {
                    settingsPickerRow(
                        "Cooldown entre notificaciones",
                        help: "Tiempo mínimo entre dos avisos del mismo tipo. Evita repetir la misma "
                            + "alerta si el consumo sigue alto durante un rato."
                    ) {
                        Picker("", selection: $vm.notificationCooldownMinutes) {
                            Text("15 min").tag(15)
                            Text("30 min (recomendado)").tag(30)
                            Text("1 hora").tag(60)
                            Text("2 horas").tag(120)
                        }
                    }
                }
            }

            // MARK: - Modo Bajo Consumo
            Section("Modo Bajo Consumo automático") {
                settingsToggle(
                    "Activar automáticamente según consumo",
                    isOn: $vm.automaticLowPowerModeEnabled,
                    help: "Permite que MacBatteryGuardian active el Modo Bajo Consumo de macOS cuando "
                        + "detecta un consumo energético elevado de forma sostenida."
                )
                if vm.automaticLowPowerModeEnabled {
                    settingsPickerRow(
                        "Activar tras consumo crítico sostenido",
                        help: "Cuánto tiempo debe mantenerse el consumo en nivel crítico antes de "
                            + "activar el Modo Bajo Consumo. Así se evitan activaciones por picos breves."
                    ) {
                        Picker("", selection: $vm.lowPowerModeActivationDelayMinutes) {
                            Text("30 min").tag(30)
                            Text("1 hora (recomendado)").tag(60)
                            Text("2 horas").tag(120)
                        }
                    }
                    settingsToggle(
                        "Desactivar al conectar el cargador",
                        isOn: $vm.deactivateLowPowerOnCharge,
                        help: "Al enchufar el Mac, la app desactiva el Modo Bajo Consumo que hubiera "
                            + "activado ella automáticamente."
                    )
                }
            }

            // MARK: - Historial
            Section("Historial") {
                settingsPickerRow(
                    "Conservar historial",
                    help: "Días que se conservan en disco los registros de batería, CPU y consumo. "
                        + "Los datos más antiguos se eliminan solos; no afecta al funcionamiento diario."
                ) {
                    Picker("", selection: $vm.historyRetentionDays) {
                        Text("7 días").tag(7)
                        Text("15 días").tag(15)
                        Text("30 días (recomendado)").tag(30)
                        Text("60 días").tag(60)
                        Text("90 días").tag(90)
                    }
                }
            }

            // MARK: - Avanzado
            Section("Avanzado") {
                HStack(spacing: 6) {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Restablecer configuración por defecto", systemImage: "arrow.counterclockwise")
                    }
                    SettingsInfoButton(
                        text: "Restaura todos los ajustes de esta pestaña a los valores iniciales. "
                            + "No borra el historial guardado."
                    )
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .alert("¿Restablecer configuración?", isPresented: $showResetAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Restablecer", role: .destructive) {
                vm.resetToDefaults()
            }
        } message: {
            Text("Se restaurarán todos los ajustes a sus valores por defecto.")
        }
    }

    // MARK: - Filas

    private func settingsLabel(_ title: String, help helpText: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
            SettingsInfoButton(text: helpText)
        }
    }

    private func settingsToggle(_ title: String, isOn: Binding<Bool>, help helpText: String) -> some View {
        LabeledContent {
            Toggle("", isOn: isOn)
                .labelsHidden()
        } label: {
            settingsLabel(title, help: helpText)
        }
    }

    private func settingsPickerRow<P: View>(
        _ title: String,
        help helpText: String,
        @ViewBuilder picker: () -> P
    ) -> some View {
        LabeledContent {
            settingsPicker(content: picker)
        } label: {
            settingsLabel(title, help: helpText)
        }
    }

    private func settingsPicker<P: View>(@ViewBuilder content: () -> P) -> some View {
        HStack {
            Spacer(minLength: 0)
            content()
                .labelsHidden()
                .fixedSize()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
