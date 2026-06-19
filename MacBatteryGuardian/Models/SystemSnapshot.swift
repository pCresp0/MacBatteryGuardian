// SystemSnapshot.swift
// Fotografía del estado del sistema (CPU, memoria, estado térmico) en un instante dado.

import Foundation

/// Fotografía completa del estado del sistema en un momento concreto.
struct SystemSnapshot: Codable, Equatable, Sendable {

    // MARK: - CPU

    /// Uso total de CPU en porcentaje (0–100). Suma de todos los núcleos normalizada.
    let cpuUsagePercent: Double

    /// Uso atribuido a procesos de usuario (%).
    let cpuUserPercent: Double

    /// Uso del kernel (%).
    let cpuSystemPercent: Double

    /// Número de núcleos de rendimiento (P-cores) en Apple Silicon.
    let performanceCoreCount: Int

    /// Número de núcleos de eficiencia (E-cores) en Apple Silicon.
    let efficiencyCoreCount: Int

    // MARK: - Memoria

    /// Memoria RAM total instalada en bytes.
    let totalMemoryBytes: UInt64

    /// Memoria activamente usada en bytes (activa + wired + comprimida).
    let usedMemoryBytes: UInt64

    /// Memoria libre en bytes.
    let freeMemoryBytes: UInt64

    /// Memoria wired (no paginable) en bytes.
    let wiredMemoryBytes: UInt64

    /// Memoria comprimida en bytes.
    let compressedMemoryBytes: UInt64

    /// Memoria inactiva en caché (recuperable) en bytes.
    let inactiveMemoryBytes: UInt64

    /// Presión de memoria del sistema (0.0–1.0).
    let memoryPressureRatio: Double

    /// Nivel de presión de memoria categorizado.
    let memoryPressureLevel: MemoryPressureLevel

    // MARK: - Estado térmico

    /// Estado térmico reportado por ProcessInfo.
    let thermalState: SystemThermalState

    // MARK: - Tiempo de actividad

    /// Segundos desde el último arranque del sistema.
    let uptimeSeconds: TimeInterval

    // MARK: - Timestamp

    let recordedAt: Date

    // MARK: - Propiedades calculadas

    var usedMemoryPercent: Double {
        guard totalMemoryBytes > 0 else { return 0 }
        return (Double(usedMemoryBytes) / Double(totalMemoryBytes)) * 100.0
    }

    var uptimeDays: Int { Int(uptimeSeconds / 86_400) }
}

// MARK: - MemoryPressureLevel

enum MemoryPressureLevel: String, Codable, Sendable, CaseIterable {
    case nominal  = "nominal"
    case fair     = "fair"
    case serious  = "serious"
    case critical = "critical"

    var localizedDescription: String {
        switch self {
        case .nominal:  return "Normal"
        case .fair:     return "Elevada"
        case .serious:  return "Alta"
        case .critical: return "Crítica"
        }
    }
}

// MARK: - SystemThermalState

/// Equivalente tipado de `ProcessInfo.ThermalState`.
enum SystemThermalState: String, Codable, Sendable {
    case nominal  = "nominal"
    case fair     = "fair"
    case serious  = "serious"
    case critical = "critical"

    var localizedDescription: String {
        switch self {
        case .nominal:  return "Normal"
        case .fair:     return "Templado"
        case .serious:  return "Caliente"
        case .critical: return "Crítico"
        }
    }

    /// Estimación en °C cuando no hay sensor numérico (solo estado cualitativo de Apple).
    var estimatedCelsius: Double {
        switch self {
        case .nominal:  return 32
        case .fair:     return 42
        case .serious:  return 52
        case .critical: return 58
        }
    }

    /// Penalización para el índice de salud (0 = ninguna, 1 = máxima).
    var healthPenaltyFactor: Double {
        switch self {
        case .nominal:  return 0.0
        case .fair:     return 0.33
        case .serious:  return 0.66
        case .critical: return 1.0
        }
    }
}

// MARK: - Placeholder para previews

extension SystemSnapshot {
    static let preview = SystemSnapshot(
        cpuUsagePercent: 12.4,
        cpuUserPercent: 8.1,
        cpuSystemPercent: 4.3,
        performanceCoreCount: 12,
        efficiencyCoreCount: 4,
        totalMemoryBytes: 36_000_000_000,
        usedMemoryBytes: 18_500_000_000,
        freeMemoryBytes: 17_500_000_000,
        wiredMemoryBytes: 4_200_000_000,
        compressedMemoryBytes: 1_100_000_000,
        inactiveMemoryBytes: 12_000_000_000,
        memoryPressureRatio: 0.45,
        memoryPressureLevel: .nominal,
        thermalState: .nominal,
        uptimeSeconds: 86_400 * 2,
        recordedAt: Date()
    )
}
