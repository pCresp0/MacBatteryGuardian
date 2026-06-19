// ShellBridge.swift
// Ejecución segura de comandos de shell de bajo privilegio.
// Los comandos con privilegios de root se delegan al helper XPC; este módulo
// solo ejecuta comandos que no requieren elevación.

import Foundation
import OSLog

/// Ejecución controlada de comandos de shell sin privilegios elevados.
enum ShellBridge {

    private static let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "ShellBridge")

    // MARK: - Resultado

    struct CommandResult: Sendable {
        let output: String
        let errorOutput: String
        let exitCode: Int32

        var succeeded: Bool { exitCode == 0 }
    }

    // MARK: - Ejecución asíncrona

    /// Ejecuta un comando y devuelve el resultado. Se ejecuta en un hilo background.
    /// Nunca bloquea el hilo principal.
    /// - Warning: NO usar para comandos que requieran privilegios de root.
    static func run(_ command: String, arguments: [String] = []) async -> CommandResult {
        await Task.detached(priority: .background) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError  = stderrPipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                logger.error("ShellBridge: fallo al ejecutar \(command): \(error.localizedDescription)")
                return CommandResult(output: "", errorOutput: error.localizedDescription, exitCode: -1)
            }

            let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

            return CommandResult(
                output: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                errorOutput: stderr.trimmingCharacters(in: .whitespacesAndNewlines),
                exitCode: process.terminationStatus
            )
        }.value
    }

    // MARK: - Lectura del estado de Low Power Mode vía pmset

    /// Lee el estado actual del Low Power Mode según pmset (sin privilegios).
    /// - Returns: `true` si está activo, `false` en caso contrario.
    static func readLowPowerModeFromPmset() async -> Bool {
        let result = await run("/usr/bin/pmset", arguments: ["-g"])
        // Buscar "lowpowermode 1" en la salida de pmset -g
        return result.output.contains("lowpowermode") && result.output.contains("lowpowermode 1")
    }
}
