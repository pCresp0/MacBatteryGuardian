// SettingsViewModel.swift
// ViewModel para la pestaña de Configuración. Bidireccional con SettingsRepository.

import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Propiedades enlazadas a SettingsRepository

    @Published var launchAtLogin: Bool {
        didSet {
            SettingsRepository.shared.launchAtLogin = launchAtLogin
            applyLaunchAtLogin(launchAtLogin)
        }
    }
    @Published var showPercentageInMenuBar: Bool {
        didSet { SettingsRepository.shared.showPercentageInMenuBar = showPercentageInMenuBar }
    }
    @Published var showConsumptionRateInMenuBar: Bool {
        didSet { SettingsRepository.shared.showConsumptionRateInMenuBar = showConsumptionRateInMenuBar }
    }
    @Published var monitoringIntervalSeconds: Int {
        didSet { SettingsRepository.shared.monitoringIntervalSeconds = monitoringIntervalSeconds }
    }
    @Published var notificationsEnabled: Bool {
        didSet { SettingsRepository.shared.notificationsEnabled = notificationsEnabled }
    }
    @Published var notificationCooldownMinutes: Int {
        didSet { SettingsRepository.shared.notificationCooldownMinutes = notificationCooldownMinutes }
    }
    @Published var automaticLowPowerModeEnabled: Bool {
        didSet { SettingsRepository.shared.automaticLowPowerModeEnabled = automaticLowPowerModeEnabled }
    }
    @Published var lowPowerModeActivationDelayMinutes: Int {
        didSet { SettingsRepository.shared.lowPowerModeActivationDelayMinutes = lowPowerModeActivationDelayMinutes }
    }
    @Published var deactivateLowPowerOnCharge: Bool {
        didSet { SettingsRepository.shared.deactivateLowPowerOnCharge = deactivateLowPowerOnCharge }
    }
    @Published var historyRetentionDays: Int {
        didSet { SettingsRepository.shared.historyRetentionDays = historyRetentionDays }
    }

    private var cancellable: AnyCancellable?

    init() {
        let s = SettingsRepository.shared.settings
        launchAtLogin                    = s.launchAtLogin
        showPercentageInMenuBar          = s.showPercentageInMenuBar
        showConsumptionRateInMenuBar     = s.showConsumptionRateInMenuBar
        monitoringIntervalSeconds        = s.monitoringIntervalSeconds
        notificationsEnabled             = s.notificationsEnabled
        notificationCooldownMinutes      = s.notificationCooldownMinutes
        automaticLowPowerModeEnabled     = s.automaticLowPowerModeEnabled
        lowPowerModeActivationDelayMinutes = s.lowPowerModeActivationDelayMinutes
        deactivateLowPowerOnCharge       = s.deactivateLowPowerOnCharge
        historyRetentionDays             = s.historyRetentionDays
    }

    // MARK: - Launch at Login

    /// Registra o elimina la app como Login Item usando SMAppService (macOS 13+).
    /// No requiere cuenta de pago: usa el nuevo sistema de Login Items de macOS.
    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Si falla (app en DerivedData sin instalar), guarda la preferencia
            // para aplicarla cuando la app esté en su ubicación definitiva.
        }
    }

    func resetToDefaults() {
        SettingsRepository.shared.resetToDefaults()
        let s = AppSettings.default
        launchAtLogin                    = s.launchAtLogin
        showPercentageInMenuBar          = s.showPercentageInMenuBar
        showConsumptionRateInMenuBar     = s.showConsumptionRateInMenuBar
        monitoringIntervalSeconds        = s.monitoringIntervalSeconds
        notificationsEnabled             = s.notificationsEnabled
        notificationCooldownMinutes      = s.notificationCooldownMinutes
        automaticLowPowerModeEnabled     = s.automaticLowPowerModeEnabled
        lowPowerModeActivationDelayMinutes = s.lowPowerModeActivationDelayMinutes
        deactivateLowPowerOnCharge       = s.deactivateLowPowerOnCharge
        historyRetentionDays             = s.historyRetentionDays
    }
}
