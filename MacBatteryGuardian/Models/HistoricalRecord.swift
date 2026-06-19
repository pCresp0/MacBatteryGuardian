// HistoricalRecord.swift
// Registro persistido de un ciclo de monitorización completo.

import Foundation

/// Un ciclo de monitorización serializado para persistencia en disco.
struct HistoricalRecord: Codable, Identifiable, Sendable {

    // MARK: - Identificación

    let id: UUID
    let timestamp: Date

    // MARK: - Batería

    let batteryPercentage: Int
    let isPluggedIn: Bool
    let isCharging: Bool
    let cycleCount: Int

    // MARK: - Sistema

    let cpuUsagePercent: Double
    let memoryUsagePercent: Double
    let memoryPressureLevel: MemoryPressureLevel
    let thermalState: SystemThermalState

    // MARK: - Consumo energético

    let ratePerHour: Double?
    let alertState: ConsumptionAlertState
    let lowPowerModeActive: Bool

    // MARK: - Procesos culpables (top 3)

    let topProcessNames: [String]

    // MARK: - Init

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        batteryPercentage: Int,
        isPluggedIn: Bool,
        isCharging: Bool,
        cycleCount: Int,
        cpuUsagePercent: Double,
        memoryUsagePercent: Double,
        memoryPressureLevel: MemoryPressureLevel,
        thermalState: SystemThermalState,
        ratePerHour: Double?,
        alertState: ConsumptionAlertState,
        lowPowerModeActive: Bool,
        topProcessNames: [String]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.batteryPercentage = batteryPercentage
        self.isPluggedIn = isPluggedIn
        self.isCharging = isCharging
        self.cycleCount = cycleCount
        self.cpuUsagePercent = cpuUsagePercent
        self.memoryUsagePercent = memoryUsagePercent
        self.memoryPressureLevel = memoryPressureLevel
        self.thermalState = thermalState
        self.ratePerHour = ratePerHour
        self.alertState = alertState
        self.lowPowerModeActive = lowPowerModeActive
        self.topProcessNames = topProcessNames
    }

    // MARK: - Fábrica desde snapshots

    static func from(
        battery: BatterySnapshot,
        system: SystemSnapshot,
        metrics: EnergyMetrics,
        topProcesses: [ProcessSnapshot]
    ) -> HistoricalRecord {
        HistoricalRecord(
            timestamp: battery.recordedAt,
            batteryPercentage: battery.percentage,
            isPluggedIn: battery.isPluggedIn,
            isCharging: battery.isCharging,
            cycleCount: battery.cycleCount,
            cpuUsagePercent: system.cpuUsagePercent,
            memoryUsagePercent: system.usedMemoryPercent,
            memoryPressureLevel: system.memoryPressureLevel,
            thermalState: system.thermalState,
            ratePerHour: metrics.currentRatePerHour,
            alertState: metrics.alertState,
            lowPowerModeActive: false,
            topProcessNames: topProcesses.prefix(3).map(\.name)
        )
    }
}
