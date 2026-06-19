// Double+Energy.swift
// Extensiones de formateo para valores relacionados con energía y rendimiento.

import Foundation

extension Double {

    // MARK: - Batería

    /// Formatea como porcentaje de batería: "78%"
    var batteryPercentageFormatted: String {
        "\(Int(self.rounded()))%"
    }

    /// Formatea como tasa de consumo: "14.5 %/h"
    var consumptionRateFormatted: String {
        String(format: "%.1f %%/h", self)
    }

    /// Formatea como porcentaje genérico con un decimal: "12.4%"
    var percentFormatted: String {
        String(format: "%.1f%%", self)
    }

    // MARK: - Memoria

    /// Convierte bytes a una cadena legible (KB, MB, GB).
    var bytesFormatted: String {
        let bytes = self
        switch bytes {
        case let b where b < 1_024:
            return String(format: "%.0f B", b)
        case let b where b < 1_048_576:
            return String(format: "%.1f KB", b / 1_024)
        case let b where b < 1_073_741_824:
            return String(format: "%.1f MB", b / 1_048_576)
        default:
            return String(format: "%.2f GB", bytes / 1_073_741_824)
        }
    }

    // MARK: - CPU

    /// Formatea como uso de CPU: "12.4%"
    var cpuUsageFormatted: String {
        String(format: "%.1f%%", self)
    }

    // MARK: - Índice de salud

    /// Formatea como índice de salud redondeado: "74"
    var healthScoreFormatted: String {
        "\(Int(self.rounded()))"
    }
}

extension UInt64 {

    /// Convierte bytes UInt64 a cadena legible.
    var bytesFormatted: String {
        Double(self).bytesFormatted
    }

    var megabytes: Double {
        Double(self) / 1_048_576.0
    }

    var gigabytes: Double {
        Double(self) / 1_073_741_824.0
    }
}
