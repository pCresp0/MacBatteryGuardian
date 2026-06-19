// IOKitBridge.swift
// Wrapper seguro para las APIs de IOKit relacionadas con la batería.
// Usa las firmas actuales del SDK macOS 26 / Xcode 26.

import Foundation
import IOKit
import IOKit.ps

/// Acceso tipado a las fuentes de alimentación del sistema mediante IOKit.
enum IOKitBridge {

    // MARK: - Claves de diccionario (string literals para compatibilidad con todos los SDK)

    private enum Keys {
        static let cycleCount     = "CycleCount"
        static let designCapacity = "DesignCapacity"
        static let isCharged      = "Is Charged"
    }

    // MARK: - Lectura de batería

    /// Lee la información completa de la primera batería disponible.
    /// - Returns: `BatterySnapshot` o `nil` si no hay batería (Mac de escritorio).
    static func readBatterySnapshot() -> BatterySnapshot? {
        guard let infoUM = IOPSCopyPowerSourcesInfo() else { return nil }
        let info = infoUM.takeRetainedValue()

        guard let sourcesUM = IOPSCopyPowerSourcesList(info) else { return nil }
        let sources = sourcesUM.takeRetainedValue() as NSArray

        for source in sources {
            guard
                let desc = powerSourceDescription(info: info, source: source as CFTypeRef),
                let type = desc[kIOPSTypeKey] as? String,
                type == kIOPSInternalBatteryType
            else { continue }

            return buildSnapshot(from: desc)
        }
        return nil
    }

    // MARK: - Construcción del snapshot

    private static func buildSnapshot(from desc: [String: Any]) -> BatterySnapshot {
        // IOPS expone Current/Max Capacity como porcentaje (0–100), no mAh.
        let percentage = desc[kIOPSCurrentCapacityKey] as? Int ?? 0

        let hardware = IORegistryBridge.readBatteryHardwareInfo()
        let maxCapacityMAh    = hardware?.maxCapacityMAh ?? 0
        let designCapacityMAh = hardware?.designCapacityMAh
        let cycleCount        = hardware?.cycleCount ?? 0

        let powerState     = desc[kIOPSPowerSourceStateKey] as? String ?? ""
        let isPluggedIn    = powerState == kIOPSACPowerValue
        let isCharging     = boolValue(desc[kIOPSIsChargingKey])
        let isFullyCharged = boolValue(desc[Keys.isCharged])

        let rawTimeToEmpty = desc[kIOPSTimeToEmptyKey] as? Int ?? -1
        let rawTimeToFull  = desc[kIOPSTimeToFullChargeKey] as? Int ?? -1
        let timeToEmpty    = rawTimeToEmpty > 0 ? rawTimeToEmpty : nil
        let timeToFull     = rawTimeToFull  > 0 ? rawTimeToFull  : nil

        let healthString   = desc[kIOPSBatteryHealthKey] as? String ?? "Unknown"

        // Temperatura: IOPS + IORegistry (VirtualTemperature suele ser más representativa del calor interno)
        let iopsTemp = TemperatureParser.celsius(from: desc[kIOPSTemperatureKey])
        let registry = IORegistryBridge.readBatteryTemperatures()
        let cellTemp = iopsTemp ?? registry.cell
        let virtualTemp = registry.virtual

        return BatterySnapshot(
            percentage: percentage,
            maxCapacityMAh: maxCapacityMAh,
            designCapacityMAh: designCapacityMAh,
            isPluggedIn: isPluggedIn,
            isCharging: isCharging,
            isFullyCharged: isFullyCharged,
            cycleCount: cycleCount,
            timeToEmptyMinutes: timeToEmpty,
            timeToFullMinutes: timeToFull,
            healthCondition: BatteryHealthCondition(rawString: healthString),
            temperatureCelsius: cellTemp,
            virtualTemperatureCelsius: virtualTemp
        )
    }

    // MARK: - Alimentación externa

    /// `true` si el Mac está conectado a corriente (cargador o sobremesa enchufada).
    static func isOnExternalPower() -> Bool {
        guard let infoUM = IOPSCopyPowerSourcesInfo() else { return false }
        let info = infoUM.takeRetainedValue()
        guard let sourcesUM = IOPSCopyPowerSourcesList(info) else { return false }
        let sources = sourcesUM.takeRetainedValue() as NSArray

        for case let source in sources {
            guard
                let desc = powerSourceDescription(info: info, source: source as CFTypeRef),
                let state = desc[kIOPSPowerSourceStateKey] as? String,
                state == kIOPSACPowerValue
            else { continue }
            return true
        }
        return false
    }

    // MARK: - Notificaciones de cambio de fuente de alimentación

    /// Crea una `CFRunLoopSource` que invoca `callback` cuando cambia el estado de la batería.
    static func createPowerSourceNotification(callback: @escaping () -> Void) -> CFRunLoopSource? {
        let ctx = Unmanaged.passRetained(callback as AnyObject)
        let src = IOPSNotificationCreateRunLoopSource({ rawCtx in
            guard let rawCtx else { return }
            let block = Unmanaged<AnyObject>.fromOpaque(rawCtx).takeUnretainedValue()
            (block as? () -> Void)?()
        }, ctx.toOpaque())
        return src?.takeRetainedValue()
    }

    // MARK: - Helpers (SDK macOS 26)

    /// En macOS 26, `IOPSGetPowerSourceDescription` devuelve `Unmanaged<CFDictionary>`.
    private static func powerSourceDescription(info: CFTypeRef, source: CFTypeRef) -> [String: Any]? {
        guard let unmanaged = IOPSGetPowerSourceDescription(info, source) else { return nil }
        return unmanaged.takeUnretainedValue() as? [String: Any]
    }

    private static func boolValue(_ value: Any?) -> Bool {
        switch value {
        case let b as Bool: return b
        case let n as Int: return n != 0
        case let n as NSNumber: return n.boolValue
        default: return false
        }
    }
}
