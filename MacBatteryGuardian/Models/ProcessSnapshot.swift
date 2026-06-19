// ProcessSnapshot.swift
// Información de un proceso del sistema capturada en un instante dado.

import Foundation

/// Estado de un proceso del sistema en un momento concreto.
struct ProcessSnapshot: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Identificación

    let id: Int32
    let name: String

    /// Ruta completa al ejecutable. Puede estar vacía si no se tiene acceso.
    let path: String

    // MARK: - Uso de recursos

    /// Porcentaje de CPU (0–100, puede superar 100 en sistemas multinúcleo).
    let cpuPercent: Double

    /// Memoria residente en bytes (RSS).
    let memoryBytes: UInt64

    /// Número de hilos activos.
    let threadCount: Int

    /// Tiempo de CPU acumulado en nanosegundos desde que el proceso arrancó.
    let cpuTimeNanoseconds: UInt64

    // MARK: - Índice de impacto energético

    /// Índice de impacto calculado por la app (0–100). Ver `EnergyImpactCalculator`.
    let energyImpactIndex: Double

    // MARK: - Timestamp

    let recordedAt: Date

    // MARK: - Propiedades calculadas

    var memoryMB: Double { Double(memoryBytes) / 1_048_576.0 }

    /// Indica si el proceso pertenece al sistema y debe mostrarse con etiqueta diferenciada.
    var isSystemProcess: Bool {
        SystemProcessNames.all.contains(name)
    }
}

// MARK: - SystemProcessNames

/// Procesos del sistema que no son candidatos a culpables, pero se muestran informativamente.
private enum SystemProcessNames {
    static let all: Set<String> = [
        "kernel_task", "launchd", "WindowServer", "mds_stores",
        "coreaudiod", "configd", "notifyd", "diskarbitrationd",
        "opendirectoryd", "securityd", "loginwindow", "Dock",
        "SystemUIServer", "Finder", "cfprefsd", "UserEventAgent"
    ]
}

// MARK: - Placeholder para previews

extension ProcessSnapshot {
    static let previewList: [ProcessSnapshot] = [
        ProcessSnapshot(id: 1234, name: "Google Chrome", path: "/Applications/Google Chrome.app",
                        cpuPercent: 18.5, memoryBytes: 850_000_000, threadCount: 48,
                        cpuTimeNanoseconds: 12_000_000_000, energyImpactIndex: 72.3, recordedAt: Date()),
        ProcessSnapshot(id: 5678, name: "Cursor", path: "/Applications/Cursor.app",
                        cpuPercent: 11.2, memoryBytes: 620_000_000, threadCount: 32,
                        cpuTimeNanoseconds: 8_000_000_000, energyImpactIndex: 54.1, recordedAt: Date()),
        ProcessSnapshot(id: 9012, name: "Docker", path: "/Applications/Docker.app",
                        cpuPercent: 8.7, memoryBytes: 1_200_000_000, threadCount: 24,
                        cpuTimeNanoseconds: 6_500_000_000, energyImpactIndex: 48.6, recordedAt: Date()),
        ProcessSnapshot(id: 3456, name: "node", path: "/usr/local/bin/node",
                        cpuPercent: 6.1, memoryBytes: 320_000_000, threadCount: 12,
                        cpuTimeNanoseconds: 4_200_000_000, energyImpactIndex: 31.2, recordedAt: Date()),
        ProcessSnapshot(id: 7890, name: "WindowServer", path: "/System/Library/PrivateFrameworks",
                        cpuPercent: 3.4, memoryBytes: 210_000_000, threadCount: 8,
                        cpuTimeNanoseconds: 2_100_000_000, energyImpactIndex: 15.8, recordedAt: Date())
    ]
}
