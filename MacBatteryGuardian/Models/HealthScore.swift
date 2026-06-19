// HealthScore.swift
// Índice de salud del sistema (0–100) con desglose por componente y recomendaciones activas.

import Foundation

/// Índice de salud del sistema calculado a partir de múltiples factores.
struct HealthScore: Codable, Equatable, Sendable {

    // MARK: - Índice global

    /// Puntuación global de 0 a 100. Cuanto mayor, mejor estado.
    let score: Int

    /// Nivel cualitativo del índice.
    let level: HealthLevel

    // MARK: - Desglose por componente (penalizaciones 0–25 cada una)

    let batteryHealthPenalty: Double
    let thermalPressurePenalty: Double
    let cpuPressurePenalty: Double
    let memoryPressurePenalty: Double
    let consumptionTrendPenalty: Double
    let uptimePenalty: Double

    // MARK: - Recomendaciones activas

    let recommendations: [HealthRecommendation]

    // MARK: - Propiedades calculadas

    var hasRecommendations: Bool { !recommendations.isEmpty }
    var criticalRecommendations: [HealthRecommendation] { recommendations.filter { $0.severity == .high } }
}

// MARK: - HealthLevel

enum HealthLevel: String, Codable, Sendable {
    case excellent = "excellent"  // 80–100
    case good      = "good"       // 65–79
    case fair      = "fair"       // 50–64
    case poor      = "poor"       // < 50

    var localizedTitle: String {
        switch self {
        case .excellent: return "Excelente"
        case .good:      return "Bueno"
        case .fair:      return "Moderado"
        case .poor:      return "Deficiente"
        }
    }

    static func from(score: Int) -> HealthLevel {
        switch score {
        case 80...: return .excellent
        case 65...: return .good
        case 50...: return .fair
        default:    return .poor
        }
    }
}

// MARK: - HealthRecommendation

/// Una recomendación concreta generada por el HealthScoreManager.
struct HealthRecommendation: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let detail: String
    let severity: RecommendationSeverity
    let category: RecommendationCategory

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        severity: RecommendationSeverity,
        category: RecommendationCategory
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.severity = severity
        self.category = category
    }
}

enum RecommendationSeverity: String, Codable, Sendable {
    case low    = "low"
    case medium = "medium"
    case high   = "high"
}

enum RecommendationCategory: String, Codable, Sendable {
    case battery  = "battery"
    case cpu      = "cpu"
    case memory   = "memory"
    case thermal  = "thermal"
    case uptime   = "uptime"
    case process  = "process"
}

// MARK: - Placeholder para previews

extension HealthScore {
    static let preview = HealthScore(
        score: 74,
        level: .good,
        batteryHealthPenalty: 3.5,
        thermalPressurePenalty: 0.0,
        cpuPressurePenalty: 8.0,
        memoryPressurePenalty: 5.0,
        consumptionTrendPenalty: 4.5,
        uptimePenalty: 5.0,
        recommendations: [
            HealthRecommendation(
                title: "Chrome utiliza demasiada CPU",
                detail: "Google Chrome lleva más de 30 minutos consumiendo más del 15% de CPU.",
                severity: .medium,
                category: .process
            ),
            HealthRecommendation(
                title: "Reinicio recomendado",
                detail: "El equipo lleva más de 5 días encendido. Un reinicio puede mejorar el rendimiento.",
                severity: .low,
                category: .uptime
            )
        ]
    )
}
