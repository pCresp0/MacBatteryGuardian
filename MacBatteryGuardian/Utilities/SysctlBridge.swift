// SysctlBridge.swift
// Wrapper seguro para llamadas sysctl relacionadas con CPU, memoria y hardware.

import Foundation
import Darwin

/// Acceso a información del sistema operativo vía sysctl.
enum SysctlBridge {

    // MARK: - CPU

    /// Número de CPUs lógicas totales.
    static var logicalCPUCount: Int {
        readInt(key: "hw.logicalcpu") ?? ProcessInfo.processInfo.processorCount
    }

    /// Número de núcleos de rendimiento (P-cores) en Apple Silicon.
    /// `hw.perflevel0.logicalcpu` corresponde a los P-cores.
    static var performanceCoreCount: Int {
        readInt(key: "hw.perflevel0.logicalcpu") ?? (logicalCPUCount / 2)
    }

    /// Número de núcleos de eficiencia (E-cores) en Apple Silicon.
    /// `hw.perflevel1.logicalcpu` corresponde a los E-cores.
    static var efficiencyCoreCount: Int {
        readInt(key: "hw.perflevel1.logicalcpu") ?? (logicalCPUCount / 2)
    }

    // MARK: - Memoria

    /// RAM total instalada en bytes.
    static var totalMemoryBytes: UInt64 {
        var size: UInt64 = 0
        var length = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &length, nil, 0)
        return size
    }

    // MARK: - Tiempo de actividad

    /// Segundos transcurridos desde el último arranque del sistema.
    static var uptimeSeconds: TimeInterval {
        var bootTime = timeval()
        var length = MemoryLayout<timeval>.size
        sysctlbyname("kern.boottime", &bootTime, &length, nil, 0)
        let bootDate = Date(timeIntervalSince1970: TimeInterval(bootTime.tv_sec))
        return Date().timeIntervalSince(bootDate)
    }

    // MARK: - Modelo de hardware

    /// Nombre del modelo de hardware (p. ej. "MacBookPro18,3").
    static var hardwareModel: String {
        readString(key: "hw.model") ?? "Unknown"
    }

    // MARK: - CPU Load (para cálculo de % de CPU)

    /// Lee los contadores de CPU del host. Devuelve nil si falla.
    static func readCPULoadInfo() -> host_cpu_load_info? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info : nil
    }

    // MARK: - VM Statistics (para memoria)

    /// Lee las estadísticas de memoria virtual del host. Devuelve nil si falla.
    static func readVMStatistics() -> vm_statistics64? {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info : nil
    }

    // MARK: - Helpers privados

    private static func readInt(key: String) -> Int? {
        var value: Int = 0
        var length = MemoryLayout<Int>.size
        let result = sysctlbyname(key, &value, &length, nil, 0)
        return result == 0 ? value : nil
    }

    private static func readString(key: String) -> String? {
        var length = 0
        guard sysctlbyname(key, nil, &length, nil, 0) == 0, length > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: length)
        guard sysctlbyname(key, &buffer, &length, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }
}
