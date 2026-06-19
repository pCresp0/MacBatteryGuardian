// PowerHelperProtocol.swift (Helper target)
// Copia del protocolo XPC necesaria en el target del helper.

import Foundation

@objc protocol PowerHelperProtocol {
    func setLowPowerMode(enabled: Bool, withReply reply: @escaping (Bool) -> Void)
    func getLowPowerModeStatus(withReply reply: @escaping (Bool) -> Void)
}
