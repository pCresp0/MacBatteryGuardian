// ConsumptionTrend.swift
// Tendencia del consumo energético derivada de la comparación entre ventanas temporales.

import Foundation

/// Dirección y magnitud de la tendencia del consumo energético.
enum ConsumptionTrend: String, Codable, Sendable, CaseIterable {

    /// El consumo se mantiene estable (variación < 10% entre ventanas).
    case stable = "stable"

    /// El consumo está creciendo de forma moderada.
    case increasing = "increasing"

    /// El consumo está creciendo de forma significativa (> 30% entre ventanas).
    case sharplyIncreasing = "sharplyIncreasing"

    /// El consumo está disminuyendo.
    case decreasing = "decreasing"

    /// No hay suficientes datos para calcular la tendencia.
    case unknown = "unknown"

    // MARK: - Presentación

    var localizedDescription: String {
        switch self {
        case .stable:            return "Estable"
        case .increasing:        return "Creciente"
        case .sharplyIncreasing: return "Crecimiento acusado"
        case .decreasing:        return "Decreciente"
        case .unknown:           return "Sin datos"
        }
    }

    /// Símbolo SF para representar la tendencia visualmente.
    var sfSymbolName: String {
        switch self {
        case .stable:            return "equal.circle"
        case .increasing:        return "arrow.up.right.circle"
        case .sharplyIncreasing: return "arrow.up.circle.fill"
        case .decreasing:        return "arrow.down.right.circle"
        case .unknown:           return "questionmark.circle"
        }
    }

    // MARK: - Inicialización a partir de tasas

    /// Calcula la tendencia comparando la tasa actual (ventana corta) con la tasa base (ventana larga).
    /// - Parameters:
    ///   - currentRate: Tasa reciente en %/hora (ventana 15–30 min).
    ///   - baseRate: Tasa de referencia en %/hora (ventana 1–3 horas).
    /// - Returns: Tendencia calculada.
    static func calculate(currentRate: Double, baseRate: Double) -> ConsumptionTrend {
        guard baseRate > 0 else { return .unknown }
        let ratio = (currentRate - baseRate) / baseRate

        switch ratio {
        case let r where r > 0.30:  return .sharplyIncreasing
        case let r where r > 0.10:  return .increasing
        case let r where r < -0.10: return .decreasing
        default:                     return .stable
        }
    }
}
