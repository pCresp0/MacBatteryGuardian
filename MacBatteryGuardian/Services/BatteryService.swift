// BatteryService.swift
// Servicio responsable exclusivamente de leer el estado de la batería desde IOKit.

import Foundation
import OSLog

/// Lee el estado de la batería del sistema en cada ciclo de monitorización.
actor BatteryService {

    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "BatteryService")

    // MARK: - Lectura

    /// Captura el estado actual de la batería.
    /// - Returns: `BatterySnapshot` o `nil` si el equipo no tiene batería.
    func readSnapshot() async -> BatterySnapshot? {
        let snapshot = IOKitBridge.readBatterySnapshot()
        if snapshot == nil {
            logger.debug("BatteryService: No se ha encontrado batería interna (posiblemente Mac de escritorio).")
        }
        return snapshot
    }
}
