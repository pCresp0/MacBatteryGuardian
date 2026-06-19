// ProcessMonitorService.swift
// Servicio que lee la lista de procesos del sistema, calcula el % de CPU por proceso
// y genera un índice de impacto energético para cada uno.

import Foundation
import OSLog

/// Lee y clasifica los procesos del sistema por impacto energético.
actor ProcessMonitorService {

    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "ProcessMonitorService")

    // MARK: - Estado interno

    /// Muestras del ciclo anterior para calcular el delta de CPU.
    private var previousSamples: [Int32: ProcInfoBridge.RawProcessData] = [:]

    // MARK: - Lectura

    /// Captura el estado de todos los procesos y devuelve el top N ordenados por impacto energético.
    /// - Parameter topCount: Número máximo de procesos a devolver.
    /// - Returns: Lista de procesos ordenada de mayor a menor impacto.
    func readTopProcesses(topCount: Int = 10) -> [ProcessSnapshot] {
        let pids = ProcInfoBridge.allPIDs()
        let cpuCount = SysctlBridge.logicalCPUCount
        let now = Date()

        var currentSamples: [Int32: ProcInfoBridge.RawProcessData] = [:]
        var snapshots: [ProcessSnapshot] = []

        for pid in pids {
            guard let current = ProcInfoBridge.rawData(for: pid) else { continue }
            currentSamples[pid] = current

            let cpuPercent: Double
            if let previous = previousSamples[pid] {
                cpuPercent = ProcInfoBridge.cpuPercent(
                    previous: previous,
                    current: current,
                    logicalCPUCount: cpuCount
                )
            } else {
                cpuPercent = 0
            }

            let impactIndex = EnergyImpactCalculator.calculate(
                cpuPercent: cpuPercent,
                memoryBytes: current.memoryBytes,
                threadCount: current.threadCount,
                cpuTimeNs: current.totalCPUTimeNs,
                previousCPUTimeNs: previousSamples[pid]?.totalCPUTimeNs,
                elapsedSeconds: now.timeIntervalSince(current.sampledAt)
            )

            let snapshot = ProcessSnapshot(
                id: pid,
                name: current.name,
                path: current.path,
                cpuPercent: cpuPercent,
                memoryBytes: current.memoryBytes,
                threadCount: current.threadCount,
                cpuTimeNanoseconds: current.totalCPUTimeNs,
                energyImpactIndex: impactIndex,
                recordedAt: now
            )
            snapshots.append(snapshot)
        }

        previousSamples = currentSamples

        return snapshots
            .filter { $0.cpuPercent > 0.01 || $0.memoryBytes > 10_000_000 }
            .sorted { $0.energyImpactIndex > $1.energyImpactIndex }
            .prefix(topCount)
            .map { $0 }
    }
}

// MARK: - EnergyImpactCalculator

/// Calcula el índice de impacto energético de un proceso combinando varios factores.
private enum EnergyImpactCalculator {

    /// Pondera CPU, memoria, threads y crecimiento de CPU time para producir un índice 0–100.
    static func calculate(
        cpuPercent: Double,
        memoryBytes: UInt64,
        threadCount: Int,
        cpuTimeNs: UInt64,
        previousCPUTimeNs: UInt64?,
        elapsedSeconds: TimeInterval
    ) -> Double {
        // Factor CPU (peso 0.40): normalizado sobre 100%
        let cpuFactor = min(cpuPercent, 100.0) * 0.40

        // Factor memoria (peso 0.20): 1 GB = 20 puntos
        let memoryGB  = Double(memoryBytes) / 1_073_741_824.0
        let memFactor = min(memoryGB * 20.0, 20.0)

        // Factor crecimiento de CPU time (peso 0.30): crescimiento rápido penaliza más
        let growthFactor: Double
        if let prev = previousCPUTimeNs, elapsedSeconds > 0 {
            let delta = Double(cpuTimeNs > prev ? cpuTimeNs - prev : 0)
            let rateNsPerSec = delta / elapsedSeconds
            // 1_000_000_000 ns/s = 100% de 1 core; normalizar a 30 puntos
            growthFactor = min((rateNsPerSec / 1_000_000_000.0) * 30.0, 30.0)
        } else {
            growthFactor = 0
        }

        // Factor threads (peso 0.10): 100 threads = 10 puntos
        let threadFactor = min(Double(threadCount) / 10.0, 10.0)

        return cpuFactor + memFactor + growthFactor + threadFactor
    }
}
