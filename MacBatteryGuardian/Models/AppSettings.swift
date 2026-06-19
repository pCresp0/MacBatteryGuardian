// AppSettings.swift
// Modelo que representa la configuración completa de la aplicación.

import Foundation

/// Configuración completa de MacBatteryGuardian. Se persiste en UserDefaults.
struct AppSettings: Codable, Equatable, Sendable {

    // MARK: - General

    /// Lanzar la app automáticamente al iniciar sesión.
    var launchAtLogin: Bool = true

    /// Mostrar el porcentaje de batería en el ícono de la barra de menú.
    var showPercentageInMenuBar: Bool = false

    /// Mostrar el consumo medio (%/h) en la barra de menú cuando hay datos suficientes.
    var showConsumptionRateInMenuBar: Bool = true

    // MARK: - Monitorización

    /// Intervalo de monitorización en segundos. Mínimo 60, máximo 900.
    /// 300s (5 min) = buen equilibrio entre datos útiles y bajo consumo energético.
    var monitoringIntervalSeconds: Int = 300

    // MARK: - Notificaciones

    var notificationsEnabled: Bool = true

    /// Intervalo mínimo entre notificaciones del mismo tipo, en minutos.
    var notificationCooldownMinutes: Int = 30

    // MARK: - Umbrales de consumo (%/hora)

    var thresholdElevated: Double = 10.0
    var thresholdWarning: Double  = 18.0
    var thresholdCritical: Double = 22.0
    var thresholdSevere: Double   = 30.0

    // MARK: - Low Power Mode automático

    /// Permitir que la app active el Low Power Mode automáticamente.
    var automaticLowPowerModeEnabled: Bool = true

    /// Duración mínima en minutos que el consumo debe superar el umbral crítico antes de activar LPM.
    var lowPowerModeActivationDelayMinutes: Int = 60

    /// Retardo en minutos antes de desactivar LPM al conectar el cargador.
    var lowPowerModeDeactivationDelayMinutes: Int = 5

    /// Desactivar LPM automáticamente al conectar el cargador.
    var deactivateLowPowerOnCharge: Bool = true

    // MARK: - Historial

    /// Días máximos de historial que se conservan.
    var historyRetentionDays: Int = 30

    // MARK: - Valores por defecto

    static let `default` = AppSettings()
}
