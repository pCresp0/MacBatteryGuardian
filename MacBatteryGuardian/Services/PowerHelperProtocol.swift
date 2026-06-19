// PowerHelperProtocol.swift
// Protocolo XPC compartido entre la app principal y el helper privilegiado.
// Debe ser Objective-C compatible para funcionar con NSXPCConnection.

import Foundation

/// Protocolo XPC para comunicación con el helper privilegiado MacBatteryGuardianHelper.
@objc protocol PowerHelperProtocol {
    /// Activa o desactiva el Low Power Mode del sistema ejecutando pmset con privilegios.
    /// - Parameters:
    ///   - enabled: `true` para activar, `false` para desactivar.
    ///   - reply: Callback con `true` si la operación se completó correctamente.
    func setLowPowerMode(enabled: Bool, withReply reply: @escaping (Bool) -> Void)

    /// Devuelve el estado actual del Low Power Mode según pmset.
    func getLowPowerModeStatus(withReply reply: @escaping (Bool) -> Void)
}
