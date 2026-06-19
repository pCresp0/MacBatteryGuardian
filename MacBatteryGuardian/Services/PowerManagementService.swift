// PowerManagementService.swift
// Gestiona la lectura y escritura del Low Power Mode del sistema.
// Lectura: ProcessInfo (API pública, sin privilegios).
// Escritura: AppleScript con "do shell script ... with administrator privileges"
//            → muestra diálogo nativo de autenticación de macOS.

import Foundation
import OSLog

/// Gestiona el estado del Low Power Mode: lectura directa y escritura vía AppleScript.
actor PowerManagementService {

    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "PowerManagementService")

    // MARK: - Lectura

    /// Indica si el Low Power Mode está activo según `ProcessInfo`.
    func isLowPowerModeEnabled() -> Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// Estado completo del modo de energía actual.
    func currentPowerModeState() async -> PowerModeState {
        let isLPM = isLowPowerModeEnabled()
        return PowerModeState(
            mode: isLPM ? .lowPower : .normal,
            source: .system,
            activatedAt: nil
        )
    }

    // MARK: - Escritura vía AppleScript

    /// Activa o desactiva el Low Power Mode ejecutando `pmset` con privilegios de administrador.
    /// macOS muestra automáticamente el diálogo de autenticación al usuario.
    /// - Returns: `true` si la operación se completó con éxito.
    @discardableResult
    func setLowPowerMode(enabled: Bool) async -> Bool {
        let value = enabled ? "1" : "0"
        let shellCmd = "pmset -a lowpowermode \(value)"

        // NSAppleScript es seguro en Swift Concurrency desde un actor porque
        // capturamos el resultado de forma síncrona dentro del bloque.
        return await Task.detached(priority: .userInitiated) {
            let source = "do shell script \"\(shellCmd)\" with administrator privileges"
            guard let script = NSAppleScript(source: source) else { return false }

            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)

            if let err = errorInfo {
                Logger(subsystem: Constants.Bundle.appIdentifier, category: "PowerManagementService")
                    .error("setLowPowerMode error: \(err)")
                return false
            }
            return true
        }.value
    }
}
