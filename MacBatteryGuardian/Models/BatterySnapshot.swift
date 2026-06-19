// BatterySnapshot.swift
// Fotografía completa del estado de la batería en un instante dado.

import Foundation

/// Estado de carga de la batería en un momento concreto.
struct BatterySnapshot: Codable, Equatable, Sendable {

    // MARK: - Capacidad

    /// Porcentaje de carga actual (0–100).
    let percentage: Int

    /// Capacidad máxima actual en mAh (puede decrecer con el uso).
    let maxCapacityMAh: Int

    /// Capacidad de diseño en mAh (valor de fábrica). Puede ser nil si IOKit no lo expone.
    let designCapacityMAh: Int?

    /// Porcentaje de salud de la batería: maxCapacity / designCapacity × 100, acotado a 100 %.
    /// La capacidad actual en mAh puede superar ligeramente la de fábrica por calibración del chip.
    var healthPercentage: Double? {
        guard let design = designCapacityMAh, design > 0 else { return nil }
        let raw = (Double(maxCapacityMAh) / Double(design)) * 100.0
        return min(100, raw)
    }

    // MARK: - Estado

    /// Indica si el cargador está conectado.
    let isPluggedIn: Bool

    /// Indica si la batería se está cargando activamente.
    let isCharging: Bool

    /// Indica si la batería está cargada al 100 % y el cargador está conectado.
    let isFullyCharged: Bool

    // MARK: - Ciclos y tiempo

    /// Número de ciclos de carga acumulados.
    let cycleCount: Int

    /// Tiempo estimado restante en minutos. `nil` si no está disponible (cargando o cálculo pendiente).
    let timeToEmptyMinutes: Int?

    /// Tiempo estimado para carga completa en minutos. `nil` si no está cargando.
    let timeToFullMinutes: Int?

    // MARK: - Salud cualitativa

    /// Estado de salud reportado por IOKit: "Good", "Fair", "Poor".
    let healthCondition: BatteryHealthCondition

    // MARK: - Temperatura

    /// Temperatura de la batería en grados Celsius (API pública: kIOPSTemperatureKey).
    let temperatureCelsius: Double?

    /// Temperatura virtual estimada por el sistema (IORegistry). Suele reflejar más calor interno.
    let virtualTemperatureCelsius: Double?

    // MARK: - Timestamp

    let recordedAt: Date

    // MARK: - Init conveniente

    init(
        percentage: Int,
        maxCapacityMAh: Int,
        designCapacityMAh: Int?,
        isPluggedIn: Bool,
        isCharging: Bool,
        isFullyCharged: Bool,
        cycleCount: Int,
        timeToEmptyMinutes: Int?,
        timeToFullMinutes: Int?,
        healthCondition: BatteryHealthCondition,
        temperatureCelsius: Double? = nil,
        virtualTemperatureCelsius: Double? = nil,
        recordedAt: Date = Date()
    ) {
        self.percentage = percentage
        self.maxCapacityMAh = maxCapacityMAh
        self.designCapacityMAh = designCapacityMAh
        self.isPluggedIn = isPluggedIn
        self.isCharging = isCharging
        self.isFullyCharged = isFullyCharged
        self.cycleCount = cycleCount
        self.timeToEmptyMinutes = timeToEmptyMinutes
        self.timeToFullMinutes = timeToFullMinutes
        self.healthCondition = healthCondition
        self.temperatureCelsius = temperatureCelsius
        self.virtualTemperatureCelsius = virtualTemperatureCelsius
        self.recordedAt = recordedAt
    }
}

// MARK: - BatteryHealthCondition

/// Estado cualitativo de la batería reportado por el sistema.
enum BatteryHealthCondition: String, Codable, Sendable {
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case unknown = "Unknown"

    init(rawString: String) {
        self = BatteryHealthCondition(rawValue: rawString) ?? .unknown
    }

    /// Descripción localizada para mostrar al usuario.
    var localizedDescription: String {
        switch self {
        case .good:    return "Buena"
        case .fair:    return "Regular"
        case .poor:    return "Deficiente"
        case .unknown: return "Desconocido"
        }
    }
}

// MARK: - Placeholder para previews

extension BatterySnapshot {
    static let preview = BatterySnapshot(
        percentage: 78,
        maxCapacityMAh: 6800,
        designCapacityMAh: 7600,
        isPluggedIn: false,
        isCharging: false,
        isFullyCharged: false,
        cycleCount: 312,
        timeToEmptyMinutes: 245,
        timeToFullMinutes: nil,
        healthCondition: .good
    )
}
