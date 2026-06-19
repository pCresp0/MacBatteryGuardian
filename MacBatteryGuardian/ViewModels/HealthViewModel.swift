// HealthViewModel.swift
// ViewModel para la pestaña de Salud del Mac.

import Foundation
import SwiftUI

@MainActor
final class HealthViewModel: ObservableObject {

    @Published private(set) var score: Int = 0
    @Published private(set) var level: HealthLevel = .good
    @Published private(set) var scoreColor: Color = .green
    @Published private(set) var recommendations: [HealthRecommendation] = []
    @Published private(set) var topCulprits: [ProcessSnapshot] = []

    // Desglose
    @Published private(set) var batteryPenaltyFormatted: String = "0"
    @Published private(set) var thermalPenaltyFormatted: String = "0"
    @Published private(set) var cpuPenaltyFormatted: String = "0"
    @Published private(set) var memoryPenaltyFormatted: String = "0"
    @Published private(set) var consumptionPenaltyFormatted: String = "0"
    @Published private(set) var uptimePenaltyFormatted: String = "0"

    // Valores numéricos para barras de impacto
    @Published private(set) var batteryPenalty: Double = 0
    @Published private(set) var thermalPenalty: Double = 0
    @Published private(set) var cpuPenalty: Double = 0
    @Published private(set) var memoryPenalty: Double = 0
    @Published private(set) var consumptionPenalty: Double = 0
    @Published private(set) var uptimePenalty: Double = 0

    /// Factores del índice para la cuadrícula de la pestaña Salud.
    var healthFactors: [HealthFactorItem] {
        [
            HealthFactorItem(
                id: "battery", icon: "battery.100", label: "Batería",
                penalty: batteryPenalty, maxPenalty: Constants.HealthScore.batteryHealthMaxPenalty, tint: .green
            ),
            HealthFactorItem(
                id: "thermal", icon: "thermometer.medium", label: "Temperatura",
                penalty: thermalPenalty, maxPenalty: Constants.HealthScore.thermalMaxPenalty, tint: .orange
            ),
            HealthFactorItem(
                id: "cpu", icon: "cpu", label: "CPU",
                penalty: cpuPenalty, maxPenalty: Constants.HealthScore.cpuMaxPenalty, tint: .blue
            ),
            HealthFactorItem(
                id: "memory", icon: "memorychip", label: "Memoria",
                penalty: memoryPenalty, maxPenalty: Constants.HealthScore.memoryMaxPenalty, tint: .purple
            ),
            HealthFactorItem(
                id: "consumption", icon: "flame.fill", label: "Consumo",
                penalty: consumptionPenalty, maxPenalty: Constants.HealthScore.consumptionTrendMaxPenalty, tint: .orange
            ),
            HealthFactorItem(
                id: "uptime", icon: "clock.arrow.circlepath", label: "Tiempo encendido",
                penalty: uptimePenalty, maxPenalty: Constants.HealthScore.uptimeMaxPenalty, tint: .secondary
            ),
        ]
    }

    func update(score: HealthScore, processes: [ProcessSnapshot]) {
        self.score = score.score
        level      = score.level
        scoreColor = .healthColor(score: score.score)
        recommendations = score.recommendations
        topCulprits     = processes.filter { !$0.isSystemProcess }.prefix(3).map { $0 }

        batteryPenalty    = score.batteryHealthPenalty
        thermalPenalty    = score.thermalPressurePenalty
        cpuPenalty        = score.cpuPressurePenalty
        memoryPenalty     = score.memoryPressurePenalty
        consumptionPenalty = score.consumptionTrendPenalty
        uptimePenalty     = score.uptimePenalty

        batteryPenaltyFormatted     = String(format: "%.0f", score.batteryHealthPenalty)
        thermalPenaltyFormatted     = String(format: "%.0f", score.thermalPressurePenalty)
        cpuPenaltyFormatted         = String(format: "%.0f", score.cpuPressurePenalty)
        memoryPenaltyFormatted      = String(format: "%.0f", score.memoryPressurePenalty)
        consumptionPenaltyFormatted = String(format: "%.0f", score.consumptionTrendPenalty)
        uptimePenaltyFormatted      = String(format: "%.0f", score.uptimePenalty)
    }
}

// MARK: - Factor de salud

struct HealthFactorItem: Identifiable {
    let id: String
    let icon: String
    let label: String
    let penalty: Double
    let maxPenalty: Double
    let tint: Color
}
