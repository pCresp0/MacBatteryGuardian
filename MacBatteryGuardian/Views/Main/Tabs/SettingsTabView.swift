// SettingsTabView.swift
// Pestaña de Configuración: todos los ajustes de la app agrupados por categoría.
// Usa SettingsViewModel como @EnvironmentObject para bindings directos.

import SwiftUI

struct SettingsTabView: View {

    // SettingsViewModel se inyecta como EnvironmentObject desde AppDelegate.openMainWindow()
    @EnvironmentObject private var vm: SettingsViewModel
    @State private var showResetAlert = false

    var body: some View {
        Form {

            // MARK: - General
            Section("General") {
                Toggle("Iniciar al arrancar el sistema", isOn: $vm.launchAtLogin)
                Toggle("Mostrar porcentaje en la barra de menú", isOn: $vm.showPercentageInMenuBar)
                Toggle("Mostrar consumo medio (%/h) en la barra de menú", isOn: $vm.showConsumptionRateInMenuBar)
            }

            // MARK: - Monitorización
            Section("Monitorización") {
                LabeledContent("Intervalo de monitorización") {
                    Picker("", selection: $vm.monitoringIntervalSeconds) {
                        Text("1 minuto").tag(60)
                        Text("2 minutos").tag(120)
                        Text("5 minutos (recomendado)").tag(300)
                        Text("10 minutos").tag(600)
                        Text("15 minutos").tag(900)
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }
            }

            // MARK: - Notificaciones
            Section("Notificaciones") {
                Toggle("Activar notificaciones", isOn: $vm.notificationsEnabled)
                if vm.notificationsEnabled {
                    LabeledContent("Cooldown entre notificaciones") {
                        Picker("", selection: $vm.notificationCooldownMinutes) {
                            Text("15 min").tag(15)
                            Text("30 min (recomendado)").tag(30)
                            Text("1 hora").tag(60)
                            Text("2 horas").tag(120)
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }
                }
            }

            // MARK: - Modo Bajo Consumo
            Section("Modo Bajo Consumo automático") {
                Toggle("Activar automáticamente según consumo", isOn: $vm.automaticLowPowerModeEnabled)
                if vm.automaticLowPowerModeEnabled {
                    LabeledContent("Activar tras consumo crítico sostenido") {
                        Picker("", selection: $vm.lowPowerModeActivationDelayMinutes) {
                            Text("30 min").tag(30)
                            Text("1 hora (recomendado)").tag(60)
                            Text("2 horas").tag(120)
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }
                    Toggle("Desactivar al conectar el cargador", isOn: $vm.deactivateLowPowerOnCharge)
                }
            }

            // MARK: - Historial
            Section("Historial") {
                LabeledContent("Conservar historial") {
                    Picker("", selection: $vm.historyRetentionDays) {
                        Text("7 días").tag(7)
                        Text("15 días").tag(15)
                        Text("30 días (recomendado)").tag(30)
                        Text("60 días").tag(60)
                        Text("90 días").tag(90)
                    }
                    .labelsHidden()
                    .frame(width: 200)
                }
            }

            // MARK: - Acerca de
            Section("Acerca de") {
                LabeledContent("Versión", value: "1.0.0")
                LabeledContent("Temperatura") {
                    Text("Batería y estimación del sistema (Apple no publica °C del procesador)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                LabeledContent("Velocidad de ventiladores") {
                    Text("No disponible via APIs públicas")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("Restablecer configuración por defecto", systemImage: "arrow.counterclockwise")
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
}
