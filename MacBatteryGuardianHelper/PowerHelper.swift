// PowerHelper.swift
// Implementación del helper privilegiado. Se ejecuta como root vía launchd.
// Implementa el protocolo XPC y ejecuta pmset para modificar el Low Power Mode.

import Foundation
import OSLog

/// Implementación del helper XPC privilegiado.
final class PowerHelper: NSObject, PowerHelperProtocol {

    private let logger = Logger(subsystem: "com.macbatteryguardian.helper", category: "PowerHelper")

    // MARK: - PowerHelperProtocol

    func setLowPowerMode(enabled: Bool, withReply reply: @escaping (Bool) -> Void) {
        let argument = enabled ? "1" : "0"
        logger.info("PowerHelper: Ejecutando pmset lowpowermode \(argument).")

        let result = runPmset(arguments: ["-a", "lowpowermode", argument])
        if result {
            logger.info("PowerHelper: pmset completado exitosamente.")
        } else {
            logger.error("PowerHelper: pmset falló.")
        }
        reply(result)
    }

    func getLowPowerModeStatus(withReply reply: @escaping (Bool) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            reply(false)
            return
        }

        let output = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        reply(output.contains("lowpowermode 1"))
    }

    // MARK: - Privado

    private func runPmset(arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            logger.error("PowerHelper: Error ejecutando pmset: \(error.localizedDescription)")
            return false
        }
    }
}
