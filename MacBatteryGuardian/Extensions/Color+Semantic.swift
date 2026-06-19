// Color+Semantic.swift
// Colores semánticos para representar estados del sistema de forma consistente.

import SwiftUI

extension Color {

    // MARK: - Batería

    /// Color del indicador de batería según el porcentaje.
    static func batteryColor(percentage: Int) -> Color {
        switch percentage {
        case 20...100: return .green
        case 10..<20:  return .yellow
        default:       return .red
        }
    }

    /// Color para el estado de alerta de consumo.
    static func alertStateColor(_ state: ConsumptionAlertState) -> Color {
        switch state {
        case .stable:   return .green
        case .elevated: return Color(hue: 0.12, saturation: 0.8, brightness: 0.9)
        case .warning:  return .yellow
        case .critical: return .orange
        case .severe:   return .red
        }
    }

    // MARK: - Salud

    /// Color del índice de salud del Mac.
    static func healthColor(score: Int) -> Color {
        switch score {
        case 80...:  return .green
        case 65..<80: return Color(hue: 0.22, saturation: 0.8, brightness: 0.85)
        case 50..<65: return .yellow
        default:     return .red
        }
    }

    // MARK: - Presión de memoria y térmica

    static func memoryPressureColor(_ level: MemoryPressureLevel) -> Color {
        switch level {
        case .nominal:  return .green
        case .fair:     return .yellow
        case .serious:  return .orange
        case .critical: return .red
        }
    }

    static func thermalStateColor(_ state: SystemThermalState) -> Color {
        switch state {
        case .nominal:  return .green
        case .fair:     return .yellow
        case .serious:  return .orange
        case .critical: return .red
        }
    }

    // MARK: - Modo Bajo Consumo (amarillo estilo icono de batería de macOS)

    static let lowPowerMode = Color(red: 1.0, green: 0.78, blue: 0.0)

    // MARK: - Colores de la app

    /// Color de acento primario de la aplicación.
    static let appAccent = Color.green

    /// Fondo del popover: transparente en macOS 26 (vidrio del sistema); material en versiones anteriores.
    static let popoverBackground = Color.clear

    /// Color de texto secundario.
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
}
