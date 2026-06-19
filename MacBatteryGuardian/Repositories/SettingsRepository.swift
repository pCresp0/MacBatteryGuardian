// SettingsRepository.swift
// Wrapper tipado sobre UserDefaults para la configuración de la app.
// Todas las claves están centralizadas como enums para evitar strings sueltos.

import Foundation
import Combine

/// Capa de acceso tipado a la configuración persistida en UserDefaults.
final class SettingsRepository: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = SettingsRepository()

    // MARK: - Publisher de cambios

    /// Emite cuando cualquier ajuste cambia.
    let settingsDidChange = PassthroughSubject<Void, Never>()

    // MARK: - UserDefaults

    private let defaults = UserDefaults.standard
    private let encoder  = JSONEncoder()
    private let decoder  = JSONDecoder()

    private init() {}

    // MARK: - AppSettings (serializado completo)

    private var cachedSettings: AppSettings?

    var settings: AppSettings {
        get {
            if let cached = cachedSettings { return cached }
            guard let data = defaults.data(forKey: Constants.UserDefaultsKeys.settings),
                  let decoded = try? decoder.decode(AppSettings.self, from: data) else {
                return .default
            }
            cachedSettings = decoded
            return decoded
        }
        set {
            cachedSettings = newValue
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Constants.UserDefaultsKeys.settings)
            }
            settingsDidChange.send()
        }
    }

    // MARK: - Accesos directos tipados

    var launchAtLogin: Bool {
        get { settings.launchAtLogin }
        set { var s = settings; s.launchAtLogin = newValue; settings = s }
    }

    var monitoringIntervalSeconds: Int {
        get { settings.monitoringIntervalSeconds }
        set { var s = settings; s.monitoringIntervalSeconds = max(60, min(newValue, 900)); settings = s }
    }

    var notificationsEnabled: Bool {
        get { settings.notificationsEnabled }
        set { var s = settings; s.notificationsEnabled = newValue; settings = s }
    }

    var notificationCooldownMinutes: Int {
        get { settings.notificationCooldownMinutes }
        set { var s = settings; s.notificationCooldownMinutes = newValue; settings = s }
    }

    var automaticLowPowerModeEnabled: Bool {
        get { settings.automaticLowPowerModeEnabled }
        set { var s = settings; s.automaticLowPowerModeEnabled = newValue; settings = s }
    }

    var lowPowerModeActivationDelayMinutes: Int {
        get { settings.lowPowerModeActivationDelayMinutes }
        set { var s = settings; s.lowPowerModeActivationDelayMinutes = newValue; settings = s }
    }

    var deactivateLowPowerOnCharge: Bool {
        get { settings.deactivateLowPowerOnCharge }
        set { var s = settings; s.deactivateLowPowerOnCharge = newValue; settings = s }
    }

    var showPercentageInMenuBar: Bool {
        get { settings.showPercentageInMenuBar }
        set { var s = settings; s.showPercentageInMenuBar = newValue; settings = s }
    }

    var showConsumptionRateInMenuBar: Bool {
        get { settings.showConsumptionRateInMenuBar }
        set { var s = settings; s.showConsumptionRateInMenuBar = newValue; settings = s }
    }

    var historyRetentionDays: Int {
        get { settings.historyRetentionDays }
        set { var s = settings; s.historyRetentionDays = max(1, min(newValue, 90)); settings = s }
    }

    // MARK: - Reset

    func resetToDefaults() {
        settings = .default
    }
}
