// EnergyMetrics.swift
// Métricas de consumo energético calculadas sobre ventanas temporales.

import Foundation

/// Métricas de consumo energético calculadas sobre múltiples ventanas de tiempo.
struct EnergyMetrics: Codable, Equatable, Sendable {

    // MARK: - Consumo por ventana temporal

    /// Consumo medio en %/hora en los últimos 15 minutos. Nil si no hay suficientes datos.
    let ratePerHour15min: Double?

    /// Consumo medio en %/hora en los últimos 30 minutos.
    let ratePerHour30min: Double?

    /// Consumo medio en %/hora en la última hora.
    let ratePerHour1h: Double?

    /// Consumo medio en %/hora en las últimas 3 horas.
    let ratePerHour3h: Double?

    // MARK: - Tendencia

    /// Tendencia del consumo comparando la ventana de 15 min vs 1 hora.
    let trend: ConsumptionTrend

    // MARK: - Autonomía estimada

    /// Autonomía estimada en minutos basada en el consumo actual. Nil si el cargador está conectado.
    let estimatedAutonomyMinutes: Int?

    // MARK: - Medias históricas

    /// Consumo medio diario en %/hora (calculado sobre historial de 7 días).
    let dailyAverageRatePerHour: Double?

    /// Consumo medio semanal en %/hora.
    let weeklyAverageRatePerHour: Double?

    // MARK: - Estado del motor de decisiones

    /// Estado de alerta determinado por el motor inteligente.
    let alertState: ConsumptionAlertState

    // MARK: - Propiedades calculadas

    /// Consumo actual representativo (ventana más corta disponible).
    var currentRatePerHour: Double? {
        ratePerHour15min ?? ratePerHour30min ?? ratePerHour1h
    }

    /// Media de todas las ventanas temporales con datos (más estable que un pico puntual).
    var averageRatePerHour: Double? {
        let rates = [ratePerHour15min, ratePerHour30min, ratePerHour1h, ratePerHour3h].compactMap { $0 }
        guard !rates.isEmpty else { return nil }
        return rates.reduce(0, +) / Double(rates.count)
    }

    /// Hay datos suficientes para mostrar consumo y estimar hora de agotamiento.
    var hasEnoughRateData: Bool {
        averageRatePerHour != nil
    }

    /// Hora estimada de agotamiento según el consumo medio y el % actual.
    func estimatedDepletionDate(batteryPercentage: Int) -> Date? {
        guard batteryPercentage > 0,
              let rate = averageRatePerHour, rate > 0 else { return nil }
        let hoursRemaining = Double(batteryPercentage) / rate
        return Date().addingTimeInterval(hoursRemaining * 3600)
    }

    /// Autonomía estimada formateada como texto legible.
    var estimatedAutonomyFormatted: String {
        guard let minutes = estimatedAutonomyMinutes, minutes > 0 else {
            return "–"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours == 0 { return "\(mins) min" }
        if mins == 0 { return "\(hours) h" }
        return "\(hours) h \(mins) min"
    }
}

// MARK: - ConsumptionAlertState

/// Estado de alerta del motor de decisiones. Determinado por tendencia sostenida, no por lectura puntual.
enum ConsumptionAlertState: String, Codable, Sendable, CaseIterable {
    /// < 10 %/hora. Sin acción necesaria.
    case stable

    /// 10–18 %/hora. Registrar silenciosamente.
    case elevated

    /// 18–22 %/hora. Notificar al usuario.
    case warning

    /// > 22 %/hora sostenido ≥ 1 hora. Activar Low Power Mode.
    case critical

    /// > 30 %/hora. Capturar culpables y notificar con urgencia.
    case severe

    var localizedTitle: String {
        switch self {
        case .stable:   return "Estable"
        case .elevated: return "Elevado"
        case .warning:  return "Atención"
        case .critical: return "Crítico"
        case .severe:   return "Muy alto"
        }
    }

    var localizedDescription: String {
        switch self {
        case .stable:
            return "El consumo energético es normal."
        case .elevated:
            return "El consumo es algo superior al habitual."
        case .warning:
            return "El consumo energético es superior al habitual."
        case .critical:
            return "Consumo elevado sostenido. Modo bajo consumo activado."
        case .severe:
            return "Se ha detectado un consumo muy elevado."
        }
    }
}

// MARK: - Placeholder para previews

extension EnergyMetrics {
    static let preview = EnergyMetrics(
        ratePerHour15min: 14.5,
        ratePerHour30min: 13.2,
        ratePerHour1h: 12.8,
        ratePerHour3h: 11.4,
        trend: .stable,
        estimatedAutonomyMinutes: 315,
        dailyAverageRatePerHour: 11.2,
        weeklyAverageRatePerHour: 10.8,
        alertState: .stable
    )
}
