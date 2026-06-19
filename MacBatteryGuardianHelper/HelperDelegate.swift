// HelperDelegate.swift
// Delegate del servicio XPC del helper privilegiado.
// Valida las conexiones entrantes y crea los objetos exportados.

import Foundation
import OSLog

/// Gestiona las conexiones XPC entrantes al helper privilegiado.
final class HelperDelegate: NSObject, NSXPCListenerDelegate {

    private let logger = Logger(subsystem: "com.macbatteryguardian.helper", category: "HelperDelegate")

    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        logger.debug("HelperDelegate: Nueva conexión XPC aceptada.")
        newConnection.exportedInterface = NSXPCInterface(with: PowerHelperProtocol.self)
        newConnection.exportedObject    = PowerHelper()
        newConnection.resume()
        return true
    }
}
