// TemperatureParser.swift
// Normaliza valores de temperatura de IOKit / IORegistry.
// Apple suele reportarlos en centésimas de °C (ej. 3129 → 31,29°C).

import Foundation

enum TemperatureParser {

    /// Convierte un valor crudo de IOKit/IORegistry a grados Celsius.
    static func celsius(from raw: Any?) -> Double? {
        guard let number = numericValue(from: raw) else { return nil }
        return celsius(fromNumeric: number)
    }

    static func celsius(fromNumeric value: Double) -> Double {
        // Valores típicos de AppleSmartBattery: 2500–4500 (= 25–45°C)
        if value > 200 { return value / 100.0 }
        // Ya en °C
        return value
    }

    private static func numericValue(from raw: Any?) -> Double? {
        switch raw {
        case let d as Double:  return d
        case let f as Float:   return Double(f)
        case let i as Int:     return Double(i)
        case let i as Int32:   return Double(i)
        case let n as NSNumber: return n.doubleValue
        default: return nil
        }
    }
}
