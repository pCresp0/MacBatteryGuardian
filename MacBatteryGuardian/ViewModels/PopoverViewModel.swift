// PopoverViewModel.swift
// ViewModel para el panel flotante del popover. Resumen ejecutivo del estado del sistema.

import Foundation
import SwiftUI

/// Datos para el panel flotante del popover.
@MainActor
final class PopoverViewModel: ObservableObject {

    // MARK: - Batería

    @Published private(set) var batteryPercentage: Int = 0
    @Published private(set) var batteryColor: Color = .green
    @Published private(set) var isPluggedIn: Bool = false
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var isFullyCharged: Bool = false
    @Published private(set) var autonomyFormatted: String = "–"
    @Published private(set) var consumptionRate: String = "–"
    /// Consumo medio en %/h (media de ventanas temporales).
    @Published private(set) var averageConsumptionRate: String = "–"
    /// Estimación legible: "Mañana a las 12:04" según consumo medio.
    @Published private(set) var estimatedDepletionLabel: String? = nil
    /// Temperatura de la batería en °C (nil en Macs de sobremesa sin batería).
    @Published private(set) var batteryTemperatureCelsius: Double? = nil
    /// Lectura térmica combinada (la más representativa disponible).
    @Published private(set) var thermalReading: ThermalReading = ThermalReading(
        celsius: nil, sourceLabel: "—", badgeLabel: "Normal", isEstimated: true, disclaimer: nil
    )
    /// Minutos para completar la carga. nil si no está cargando o no hay dato válido.
    @Published private(set) var minutesToFull: Int? = nil
    /// Texto "Carga completa en …" cuando hay estimación de carga.
    var chargeCompleteFormatted: String? {
        guard isCharging, let mins = minutesToFull, mins > 0 else { return nil }
        return Date.chargeCompleteLabel(minutes: mins)
    }
    /// Minutos restantes de batería. nil si está enchufado o sin dato válido.
    @Published private(set) var minutesToEmpty: Int? = nil
    /// true cuando la app tiene datos reales (al menos un ciclo completado).
    @Published private(set) var hasRealData: Bool = false
    /// false en Macs sin batería interna.
    @Published private(set) var hasInternalBattery: Bool = false

    // MARK: - Sistema

    @Published private(set) var cpuUsage: String = "–"
    @Published private(set) var memoryUsage: String = "–"
    @Published private(set) var thermalState: SystemThermalState = .nominal

    // MARK: - Modo

    @Published private(set) var powerModeState: PowerModeState = .normal
    @Published private(set) var alertState: ConsumptionAlertState = .stable
    @Published private(set) var alertColor: Color = .green

    // MARK: - Procesos

    @Published private(set) var topProcesses: [ProcessSnapshot] = []

    // MARK: - Timestamp

    @Published private(set) var lastUpdateFormatted: String = "–"

    // MARK: - Actualización

    func update(
        battery: BatterySnapshot?,
        system: SystemSnapshot?,
        metrics: EnergyMetrics?,
        processes: [ProcessSnapshot],
        powerMode: PowerModeState
    ) {
        // Batería
        hasInternalBattery = battery != nil
        if let battery {
            batteryPercentage         = battery.percentage
            batteryColor              = .batteryColor(percentage: battery.percentage)
            isPluggedIn               = battery.isPluggedIn
            isCharging                = battery.isCharging
            isFullyCharged            = battery.isFullyCharged
            batteryTemperatureCelsius = battery.temperatureCelsius
            minutesToFull  = battery.isCharging
                ? battery.timeToFullMinutes.flatMap { $0 > 0 ? $0 : nil }
                : nil
            minutesToEmpty = !battery.isPluggedIn
                ? battery.timeToEmptyMinutes.flatMap { $0 > 0 ? $0 : nil }
                : nil
        } else {
            // Mac sin batería interna o lectura fallida: detectar si hay corriente
            isPluggedIn = IOKitBridge.isOnExternalPower()
            isCharging  = false
            isFullyCharged = false
            batteryPercentage = 0
        }

        // Sistema: CPU muestra "–" en la primera lectura (delta=0 por diseño del servicio)
        if let system {
            let rawCPU = system.cpuUsagePercent
            cpuUsage     = (rawCPU < 0.1 && !hasRealData) ? "–" : rawCPU.cpuUsageFormatted
            memoryUsage  = system.usedMemoryPercent.percentFormatted
            thermalState = system.thermalState
            thermalReading = ThermalCalculator.reading(
                battery: battery,
                thermalState: system.thermalState,
                cpuUsagePercent: rawCPU > 0.1 ? rawCPU : nil
            )
        }

        // Métricas energéticas
        autonomyFormatted = metrics?.estimatedAutonomyFormatted ?? "–"
        consumptionRate = metrics?.currentRatePerHour.map {
            String(format: "%.1f %%/h", $0)
        } ?? "–"
        averageConsumptionRate = metrics?.averageRatePerHour.map {
            String(format: "%.1f %%/h (media)", $0)
        } ?? "–"

        if let battery, !battery.isPluggedIn,
           metrics?.hasEnoughRateData == true,
           let depletion = metrics?.estimatedDepletionDate(batteryPercentage: battery.percentage) {
            estimatedDepletionLabel = depletion.depletionEstimateFormatted
        } else {
            estimatedDepletionLabel = nil
        }

        // Estado general
        powerModeState      = powerMode
        alertState          = metrics?.alertState ?? .stable
        alertColor          = .alertStateColor(alertState)
        topProcesses        = Array(processes.prefix(5))
        lastUpdateFormatted = Date().shortTimeFormatted
        hasRealData         = true
    }

    /// Carga al 100 % según IOKit o porcentaje (≥ 99 %).
    var isBatteryFull: Bool {
        isFullyCharged || batteryPercentage >= 99
    }

    func syncPowerMode(_ state: PowerModeState) {
        powerModeState = state
    }
}
