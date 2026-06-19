// HealthScoreManager.swift
// Calcula el índice de salud del sistema (0–100) combinando múltiples factores
// y genera recomendaciones accionables cuando el índice baja de 50.

import Foundation

/// Calcula el índice de salud del sistema y las recomendaciones asociadas.
final class HealthScoreManager: @unchecked Sendable {

    // MARK: - Cálculo del índice

    /// Calcula el `HealthScore` a partir de los últimos snapshots disponibles.
    func calculateScore(
        battery: BatterySnapshot?,
        system: SystemSnapshot?,
        metrics: EnergyMetrics?,
        processes: [ProcessSnapshot]
    ) -> HealthScore {
        var totalPenalty: Double = 0

        let batteryPenalty     = calculateBatteryPenalty(battery: battery)
        let thermalPenalty     = calculateThermalPenalty(system: system)
        let cpuPenalty         = calculateCPUPenalty(system: system)
        let memoryPenalty      = calculateMemoryPenalty(system: system)
        let consumptionPenalty = calculateConsumptionPenalty(metrics: metrics)
        let uptimePenalty      = calculateUptimePenalty(system: system)

        totalPenalty = batteryPenalty + thermalPenalty + cpuPenalty +
                       memoryPenalty + consumptionPenalty + uptimePenalty

        let score = max(0, Int((100.0 - totalPenalty).rounded()))
        let level = HealthLevel.from(score: score)

        let recommendations = buildRecommendations(
            score: score,
            battery: battery,
            system: system,
            metrics: metrics,
            processes: processes
        )

        return HealthScore(
            score: score,
            level: level,
            batteryHealthPenalty: batteryPenalty,
            thermalPressurePenalty: thermalPenalty,
            cpuPressurePenalty: cpuPenalty,
            memoryPressurePenalty: memoryPenalty,
            consumptionTrendPenalty: consumptionPenalty,
            uptimePenalty: uptimePenalty,
            recommendations: recommendations
        )
    }

    // MARK: - Penalizaciones individuales

    private func calculateBatteryPenalty(battery: BatterySnapshot?) -> Double {
        guard let battery else { return 0 }
        let max = Constants.HealthScore.batteryHealthMaxPenalty

        if let health = battery.healthPercentage {
            switch health {
            case 90...: return 0
            case 80..<90: return max * 0.25
            case 70..<80: return max * 0.50
            case 60..<70: return max * 0.75
            default: return max
            }
        }

        switch battery.healthCondition {
        case .good:    return 0
        case .fair:    return max * 0.5
        case .poor:    return max
        case .unknown: return max * 0.25
        }
    }

    private func calculateThermalPenalty(system: SystemSnapshot?) -> Double {
        guard let system else { return 0 }
        let max = Constants.HealthScore.thermalMaxPenalty
        return max * system.thermalState.healthPenaltyFactor
    }

    private func calculateCPUPenalty(system: SystemSnapshot?) -> Double {
        guard let system else { return 0 }
        let max = Constants.HealthScore.cpuMaxPenalty
        switch system.cpuUsagePercent {
        case let c where c >= 80: return max
        case let c where c >= 60: return max * 0.75
        case let c where c >= 40: return max * 0.50
        case let c where c >= 20: return max * 0.25
        default: return 0
        }
    }

    private func calculateMemoryPenalty(system: SystemSnapshot?) -> Double {
        guard let system else { return 0 }
        let max = Constants.HealthScore.memoryMaxPenalty
        switch system.memoryPressureLevel {
        case .nominal:  return 0
        case .fair:     return max * 0.33
        case .serious:  return max * 0.66
        case .critical: return max
        }
    }

    private func calculateConsumptionPenalty(metrics: EnergyMetrics?) -> Double {
        guard let metrics else { return 0 }
        let max = Constants.HealthScore.consumptionTrendMaxPenalty
        switch metrics.alertState {
        case .stable:   return 0
        case .elevated: return max * 0.25
        case .warning:  return max * 0.50
        case .critical: return max * 0.75
        case .severe:   return max
        }
    }

    private func calculateUptimePenalty(system: SystemSnapshot?) -> Double {
        guard let system else { return 0 }
        let max = Constants.HealthScore.uptimeMaxPenalty
        let days = system.uptimeDays
        guard days >= Constants.HealthScore.uptimeDaysThreshold else { return 0 }
        let extraDays = days - Constants.HealthScore.uptimeDaysThreshold
        return min(max, Double(extraDays) * (max / 14.0))
    }

    // MARK: - Recomendaciones

    private func buildRecommendations(
        score: Int,
        battery: BatterySnapshot?,
        system: SystemSnapshot?,
        metrics: EnergyMetrics?,
        processes: [ProcessSnapshot]
    ) -> [HealthRecommendation] {
        var recs: [HealthRecommendation] = []

        if let battery, let health = battery.healthPercentage, health < Constants.Battery.healthWarningPercent {
            recs.append(HealthRecommendation(
                title: "Capacidad de la batería reducida",
                detail: "La batería ha perdido \(String(format: "%.0f", 100 - health))% de su capacidad original. Considera revisarla.",
                severity: health < 70 ? .high : .medium,
                category: .battery
            ))
        }

        if let system, system.thermalState == .serious || system.thermalState == .critical {
            recs.append(HealthRecommendation(
                title: "Temperatura elevada del sistema",
                detail: "El sistema detecta una presión térmica \(system.thermalState.localizedDescription.lowercased()). Cierra aplicaciones que no necesites.",
                severity: system.thermalState == .critical ? .high : .medium,
                category: .thermal
            ))
        }

        if let system, system.uptimeDays >= Constants.HealthScore.uptimeDaysThreshold {
            recs.append(HealthRecommendation(
                title: "Reinicio recomendado",
                detail: "El equipo lleva \(system.uptimeDays) días encendido. Un reinicio puede mejorar el rendimiento.",
                severity: system.uptimeDays > 14 ? .medium : .low,
                category: .uptime
            ))
        }

        if let metrics, metrics.alertState == .critical || metrics.alertState == .severe {
            recs.append(HealthRecommendation(
                title: "Modo Bajo Consumo recomendado",
                detail: "El consumo energético es muy elevado. Activa el Modo Bajo Consumo para preservar la autonomía.",
                severity: .high,
                category: .battery
            ))
        }

        // Top proceso problemático
        if let topProcess = processes.first(where: { $0.cpuPercent > 15 && !$0.isSystemProcess }) {
            recs.append(HealthRecommendation(
                title: "\(topProcess.name) está consumiendo demasiados recursos",
                detail: "\(topProcess.name) usa \(topProcess.cpuPercent.cpuUsageFormatted) de CPU y \(topProcess.memoryMB.bytesFormatted) de memoria.",
                severity: topProcess.cpuPercent > 30 ? .high : .medium,
                category: .process
            ))
        }

        return recs
    }
}
