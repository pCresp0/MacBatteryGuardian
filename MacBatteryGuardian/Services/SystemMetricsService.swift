// SystemMetricsService.swift
// Servicio responsable de leer métricas de CPU y memoria del sistema.
// Mantiene la muestra anterior de CPU para calcular deltas correctamente.

import Foundation
import Darwin
import OSLog

/// Lee métricas de CPU y memoria del sistema operativo.
actor SystemMetricsService {

    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "SystemMetricsService")

    // MARK: - Estado interno

    /// Última lectura de CPU guardada para calcular el delta en el siguiente ciclo.
    private var previousCPULoad: host_cpu_load_info?

    // MARK: - CPU

    /// Calcula el porcentaje de uso de CPU respecto a la última muestra.
    /// La primera llamada devuelve 0 ya que no hay muestra previa.
    func readCPUUsage() -> (total: Double, user: Double, system: Double) {
        guard let current = SysctlBridge.readCPULoadInfo() else {
            return (0, 0, 0)
        }
        defer { previousCPULoad = current }

        guard let previous = previousCPULoad else {
            // Primera muestra: no hay delta todavía.
            return (0, 0, 0)
        }

        let userDelta   = Double(current.cpu_ticks.0) - Double(previous.cpu_ticks.0)
        let systemDelta = Double(current.cpu_ticks.1) - Double(previous.cpu_ticks.1)
        let idleDelta   = Double(current.cpu_ticks.2) - Double(previous.cpu_ticks.2)
        let niceDelta   = Double(current.cpu_ticks.3) - Double(previous.cpu_ticks.3)

        let total = userDelta + systemDelta + idleDelta + niceDelta
        guard total > 0 else { return (0, 0, 0) }

        let userPercent   = (userDelta / total) * 100.0
        let systemPercent = (systemDelta / total) * 100.0
        let totalPercent  = userPercent + systemPercent + (niceDelta / total) * 100.0

        return (
            total: min(totalPercent, 100.0),
            user: userPercent,
            system: systemPercent
        )
    }

    // MARK: - Memoria

    /// Calcula el estado de la memoria del sistema.
    func readMemoryState() -> (
        used: UInt64,
        free: UInt64,
        wired: UInt64,
        compressed: UInt64,
        inactive: UInt64,
        pressureRatio: Double,
        pressureLevel: MemoryPressureLevel
    ) {
        let total = SysctlBridge.totalMemoryBytes
        guard let vm = SysctlBridge.readVMStatistics(), total > 0 else {
            return (0, 0, 0, 0, 0, 0, .nominal)
        }

        // getpagesize() es thread-safe y concurrency-safe en Swift 6
        let pageSize = UInt64(getpagesize())
        let active      = UInt64(vm.active_count)     * pageSize
        let inactive    = UInt64(vm.inactive_count)   * pageSize
        let wired       = UInt64(vm.wire_count)       * pageSize
        let compressed  = UInt64(vm.compressor_page_count) * pageSize
        let free        = UInt64(vm.free_count)       * pageSize

        // Memoria "usada" = activa + wired + comprimida (sin caché inactiva)
        let used = active + wired + compressed

        let pressureRatio = Double(used) / Double(total)

        let level: MemoryPressureLevel
        switch pressureRatio {
        case let r where r >= 0.90: level = .critical
        case let r where r >= 0.75: level = .serious
        case let r where r >= 0.60: level = .fair
        default:                     level = .nominal
        }

        return (used, free, wired, compressed, inactive, pressureRatio, level)
    }

    // MARK: - Snapshot completo

    /// Captura el estado completo del sistema.
    func readSnapshot() -> SystemSnapshot {
        let cpu = readCPUUsage()
        let mem = readMemoryState()
        let total = SysctlBridge.totalMemoryBytes

        let thermalStateRaw = ProcessInfo.processInfo.thermalState
        let thermalState: SystemThermalState
        switch thermalStateRaw {
        case .nominal:  thermalState = .nominal
        case .fair:     thermalState = .fair
        case .serious:  thermalState = .serious
        case .critical: thermalState = .critical
        @unknown default: thermalState = .nominal
        }

        return SystemSnapshot(
            cpuUsagePercent: cpu.total,
            cpuUserPercent: cpu.user,
            cpuSystemPercent: cpu.system,
            performanceCoreCount: SysctlBridge.performanceCoreCount,
            efficiencyCoreCount: SysctlBridge.efficiencyCoreCount,
            totalMemoryBytes: total,
            usedMemoryBytes: mem.used,
            freeMemoryBytes: mem.free,
            wiredMemoryBytes: mem.wired,
            compressedMemoryBytes: mem.compressed,
            inactiveMemoryBytes: mem.inactive,
            memoryPressureRatio: mem.pressureRatio,
            memoryPressureLevel: mem.pressureLevel,
            thermalState: thermalState,
            uptimeSeconds: SysctlBridge.uptimeSeconds,
            recordedAt: Date()
        )
    }
}
