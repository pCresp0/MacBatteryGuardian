// ThermalCalculator.swift
// Combina sensores de batería y estado térmico de macOS en una lectura honesta.
//
// LIMITACIÓN: Apple NO expone la temperatura del procesador en APIs públicas.
// Lo que mostramos es la mejor estimación disponible (batería + VirtualTemperature + estado térmico).

import Foundation

struct ThermalReading: Sendable {
    let celsius: Double?
    let sourceLabel: String
    let badgeLabel: String
    let isEstimated: Bool
    let disclaimer: String?
}

enum ThermalCalculator {

    static func reading(
        battery: BatterySnapshot?,
        thermalState: SystemThermalState,
        cpuUsagePercent: Double? = nil
    ) -> ThermalReading {
        let cell    = battery?.temperatureCelsius
        let virtual = battery?.virtualTemperatureCelsius

        // Máximo entre sensores numéricos de batería
        var bestCelsius = [cell, virtual].compactMap { $0 }.max()

        // Si macOS ya detecta estrés térmico, no mostrar "Normal" con 31°C
        if thermalState != .nominal {
            let stateC = thermalState.estimatedCelsius
            bestCelsius = max(bestCelsius ?? 0, stateC)
        }

        // CPU muy alta sin sensor: subir ligeramente la estimación visual (proxy indirecto)
        if let cpu = cpuUsagePercent, cpu > 75, thermalState == .nominal {
            let cpuBoost = 32 + (cpu - 75) * 0.25  // hasta ~38°C visual con CPU al 100%
            bestCelsius = max(bestCelsius ?? 0, cpuBoost)
        }

        let celsius = bestCelsius
        let isEstimated = cell == nil && virtual == nil

        let source: String
        if let virtual, let cell, virtual > cell + 1.5 {
            source = "estimación del sistema"
        } else if cell != nil {
            source = "temperatura batería"
        } else if thermalState != .nominal {
            source = "estado térmico del sistema"
        } else {
            source = "estimación indirecta"
        }

        let badge = badgeLabel(celsius: celsius, thermalState: thermalState)

        let disclaimer: String?
        if isEstimated || (celsius ?? 0) < 40 && thermalState == .nominal {
            disclaimer = "Apple no publica la temperatura del procesador. Esta lectura es de la batería/sistema y puede ser menor que la sensación de calor del chasis."
        } else {
            disclaimer = nil
        }

        return ThermalReading(
            celsius: celsius,
            sourceLabel: source,
            badgeLabel: badge,
            isEstimated: isEstimated,
            disclaimer: disclaimer
        )
    }

    private static func badgeLabel(celsius: Double?, thermalState: SystemThermalState) -> String {
        // Priorizar estado térmico de Apple si está elevado
        switch thermalState {
        case .critical: return "Crítico"
        case .serious:  return "Caliente"
        case .fair:     return "Templado"
        case .nominal:  break
        }

        guard let c = celsius else { return thermalState.localizedDescription }

        switch c {
        case ..<35:   return "Normal"
        case 35..<42: return "Templado"
        case 42..<48: return "Caliente"
        default:      return "Muy caliente"
        }
    }
}
