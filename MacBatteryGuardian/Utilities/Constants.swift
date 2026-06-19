// Constants.swift
// Constantes globales de la aplicación organizadas por dominio.

import Foundation

enum Constants {

    // MARK: - Bundle e identificadores

    enum Bundle {
        static let appIdentifier    = "com.macbatteryguardian.app"
        static let helperIdentifier = "com.macbatteryguardian.helper"
    }

    // MARK: - Monitorización

    enum Monitoring {
        /// Intervalo de monitorización normal en segundos.
        static let defaultIntervalSeconds: Int = 300

        /// Intervalo de monitorización elevado cuando hay alerta activa.
        static let alertIntervalSeconds: Int = 120

        /// Máximo número de lecturas a mantener en memoria para el motor de decisiones.
        static let slidingWindowSize: Int = 36  // 3 horas a 5 min/lectura

        /// Lecturas mínimas necesarias para calcular una tendencia fiable.
        static let minimumReadingsForTrend: Int = 3

        /// Tiempo mínimo entre la primera y la última lectura para estimar %/h (evita picos al arrancar).
        static let minimumSampleDurationSeconds: TimeInterval = 300
    }

    // MARK: - Umbrales de consumo (%/hora)

    enum Thresholds {
        /// Tope físico: no se puede descargar más del 100 % en una hora.
        static let maximumRatePerHour: Double = 100.0

        static let elevated: Double = 10.0
        static let warning: Double  = 18.0
        static let critical: Double = 22.0
        static let severe: Double   = 30.0

        /// Lecturas consecutivas en el mismo nivel para confirmar la transición de estado.
        static let confirmationReadingsUp: Int   = 2
        static let confirmationReadingsDown: Int = 3
    }

    // MARK: - Low Power Mode

    enum LowPower {
        /// Minutos de consumo crítico sostenido antes de activar LPM automáticamente.
        static let activationDelayMinutes: Int = 60
        /// Minutos de espera tras conectar el cargador antes de desactivar LPM.
        static let deactivationDelayMinutes: Int = 5
    }

    // MARK: - Historial

    enum History {
        static let retentionDays: Int = 30
        static let applicationSupportFolder = "MacBatteryGuardian"
        static let historyFileName = "history"
    }

    // MARK: - Health Score (penalizaciones máximas por componente)

    enum HealthScore {
        static let batteryHealthMaxPenalty: Double   = 20.0
        static let thermalMaxPenalty: Double         = 20.0
        static let cpuMaxPenalty: Double             = 20.0
        static let memoryMaxPenalty: Double          = 15.0
        static let consumptionTrendMaxPenalty: Double = 15.0
        static let uptimeMaxPenalty: Double          = 10.0

        static let uptimeDaysThreshold: Int = 7  // A partir de este uptime se penaliza
    }

    // MARK: - Ciclos de batería

    enum Battery {
        /// Ciclos a partir de los cuales se considera la batería en estado "fair".
        static let warnCycles: Int = 500
        /// Ciclos a partir de los cuales se considera la batería en estado "poor".
        static let criticalCycles: Int = 800
        /// Porcentaje de salud a partir del cual se muestra advertencia.
        static let healthWarningPercent: Double = 80.0
    }

    // MARK: - Notificaciones

    enum Notifications {
        static let categoryWarning  = "BATTERY_WARNING"
        static let categoryCritical = "BATTERY_CRITICAL"
        static let categorySevere   = "BATTERY_SEVERE"
        static let categoryHealth   = "HEALTH_RECOMMENDATION"
    }

    // MARK: - UserDefaults keys

    enum UserDefaultsKeys {
        static let settings = "AppSettings"
        static let lastHistoryCleanup = "LastHistoryCleanup"
    }
}
