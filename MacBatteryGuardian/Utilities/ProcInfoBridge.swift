// ProcInfoBridge.swift
// Wrapper seguro para proc_info APIs de Darwin: lista de procesos, uso de CPU y memoria por PID.

import Foundation
import Darwin

/// Lectura de información de procesos del sistema mediante `proc_info`.
enum ProcInfoBridge {

    // MARK: - Lista de PIDs

    /// Devuelve todos los PIDs activos del sistema. No incluye el PID 0.
    static func allPIDs() -> [Int32] {
        let bufferSize = proc_listallpids(nil, 0)
        guard bufferSize > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(bufferSize) + 16)
        let count = proc_listallpids(&pids, Int32(pids.count) * Int32(MemoryLayout<Int32>.size))
        guard count > 0 else { return [] }
        return Array(pids[0..<Int(count)]).filter { $0 > 0 }
    }

    // MARK: - Información de un proceso

    /// Lee la información de tarea de un PID concreto (CPU time, memoria, hilos).
    /// - Returns: `proc_taskinfo` o nil si el PID ya no existe o no tenemos permisos.
    static func taskInfo(for pid: Int32) -> proc_taskinfo? {
        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size)
        return result == size ? info : nil
    }

    /// Nombre del proceso para un PID dado (máximo 16 caracteres via `proc_name`).
    static func processName(for pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: Int(MAXCOMLEN) + 1)
        proc_name(pid, &buffer, UInt32(buffer.count))
        let name = String(cString: buffer)
        return name.isEmpty ? "Unknown" : name
    }

    /// Ruta completa al ejecutable de un PID. Puede estar vacía si no hay acceso.
    static func processPath(for pid: Int32) -> String {
        // PROC_PIDPATHINFO_MAXSIZE = 4096 bytes según proc_info.h
        let maxSize = 4096
        var buffer = [CChar](repeating: 0, count: maxSize)
        let result = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard result > 0 else { return "" }
        return String(cString: buffer)
    }

    // MARK: - Snapshot completo de un proceso

    /// Genera un `RawProcessData` para un PID, necesario para calcular el delta de CPU entre muestras.
    struct RawProcessData: Sendable {
        let pid: Int32
        let name: String
        let path: String
        let totalCPUTimeNs: UInt64  // user_time + system_time en nanosegundos
        let memoryBytes: UInt64
        let threadCount: Int
        let sampledAt: Date
    }

    static func rawData(for pid: Int32) -> RawProcessData? {
        guard let info = taskInfo(for: pid) else { return nil }

        let userNs   = UInt64(info.pti_total_user)   // ya en nanosegundos
        let systemNs = UInt64(info.pti_total_system)
        let totalNs  = userNs + systemNs

        let memory  = UInt64(info.pti_resident_size)
        let threads = Int(info.pti_threadnum)

        let name = processName(for: pid)
        guard !name.isEmpty, name != "Unknown" else { return nil }

        // Excluir PID 0 y el propio proceso de la app
        guard pid > 1, pid != ProcessInfo.processInfo.processIdentifier else { return nil }

        return RawProcessData(
            pid: pid,
            name: name,
            path: processPath(for: pid),
            totalCPUTimeNs: totalNs,
            memoryBytes: memory,
            threadCount: threads,
            sampledAt: Date()
        )
    }

    // MARK: - Cálculo de % CPU entre muestras

    /// Calcula el % de CPU de un proceso dado dos muestras consecutivas.
    /// - Parameters:
    ///   - previous: Muestra anterior.
    ///   - current: Muestra actual.
    ///   - logicalCPUCount: Número de CPUs lógicas para normalizar al 100%.
    /// - Returns: Porcentaje de CPU (0–100 normalizado).
    static func cpuPercent(
        previous: RawProcessData,
        current: RawProcessData,
        logicalCPUCount: Int
    ) -> Double {
        guard current.totalCPUTimeNs >= previous.totalCPUTimeNs else { return 0 }

        let cpuTimeDeltaNs = current.totalCPUTimeNs - previous.totalCPUTimeNs
        let wallTimeDeltaNs = UInt64(max(current.sampledAt.timeIntervalSince(previous.sampledAt) * 1_000_000_000, 1))

        let rawPercent = (Double(cpuTimeDeltaNs) / Double(wallTimeDeltaNs)) * 100.0
        // Normalizado al total de CPUs para que el máximo sea 100% del sistema
        return min(rawPercent / Double(max(logicalCPUCount, 1)), 100.0)
    }
}
