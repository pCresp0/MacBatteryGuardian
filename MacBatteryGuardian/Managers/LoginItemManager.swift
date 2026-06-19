// LoginItemManager.swift
// Gestiona el registro de la app como Login Item usando ServiceManagement (macOS 13+).

import Foundation
import ServiceManagement
import OSLog

/// Gestiona el inicio automático de la app al iniciar sesión.
final class LoginItemManager: @unchecked Sendable {

    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "LoginItemManager")

    // MARK: - Estado

    /// Indica si la app está registrada como Login Item.
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    // MARK: - Activación / Desactivación

    /// Registra la app como Login Item.
    func enable() {
        do {
            try SMAppService.mainApp.register()
            logger.info("LoginItemManager: App registrada como Login Item.")
        } catch {
            logger.error("LoginItemManager: Error al registrar Login Item: \(error.localizedDescription)")
        }
    }

    /// Elimina el registro de Login Item.
    func disable() {
        do {
            try SMAppService.mainApp.unregister()
            logger.info("LoginItemManager: App eliminada de Login Items.")
        } catch {
            logger.error("LoginItemManager: Error al eliminar Login Item: \(error.localizedDescription)")
        }
    }

    /// Alterna el estado del Login Item.
    func toggle() {
        if isEnabled { disable() } else { enable() }
    }
}
