// IORegistryBridge.swift
// Lectura de datos de hardware vía IORegistry (AppleSmartBattery).
// Complementa IOPS con capacidades en mAh, ciclos y temperaturas.

import Foundation
import IOKit

/// Capacidades y ciclos reales desde el chip de la batería (mAh, no %).
struct BatteryHardwareInfo: Sendable {
    let designCapacityMAh: Int?
    let maxCapacityMAh: Int?
    let currentChargeMAh: Int?
    let cycleCount: Int?
}

enum IORegistryBridge {

    // MARK: - Hardware

    /// Capacidades en mAh y ciclos desde AppleSmartBattery.
    static func readBatteryHardwareInfo() -> BatteryHardwareInfo? {
        guard let service = smartBatteryService() else { return nil }
        defer { IOObjectRelease(service) }

        // MaxCapacity a nivel raíz en IORegistry es % (0–100), igual que IOPS.
        // Los mAh reales están en AppleRawMaxCapacity / DesignCapacity.
        let design = intProperty("DesignCapacity", from: service)
        let maxMAh = intProperty("AppleRawMaxCapacity", from: service)
        let chargeMAh = intProperty("AppleRawCurrentCapacity", from: service)
        let cycles = intProperty("CycleCount", from: service)

        guard design != nil || maxMAh != nil || cycles != nil else { return nil }

        return BatteryHardwareInfo(
            designCapacityMAh: design,
            maxCapacityMAh: maxMAh,
            currentChargeMAh: chargeMAh,
            cycleCount: cycles
        )
    }

    /// Temperaturas de la batería interna desde AppleSmartBattery.
    /// - Returns: (temperatura celda, temperatura virtual estimada) en °C.
    static func readBatteryTemperatures() -> (cell: Double?, virtual: Double?) {
        guard let service = smartBatteryService() else { return (nil, nil) }
        defer { IOObjectRelease(service) }

        let cell = readProperty("Temperature", from: service).flatMap { TemperatureParser.celsius(from: $0) }
        let virtual = readProperty("VirtualTemperature", from: service).flatMap { TemperatureParser.celsius(from: $0) }
        return (cell, virtual)
    }

    // MARK: - IORegistry

    private static func smartBatteryService() -> io_registry_entry_t? {
        let matching = IOServiceMatching("AppleSmartBattery")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != 0 else { return nil }
        return service
    }

    private static func readProperty(_ key: String, from service: io_registry_entry_t) -> Any? {
        guard let unmanaged = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        return unmanaged.takeRetainedValue()
    }

    private static func intProperty(_ key: String, from service: io_registry_entry_t) -> Int? {
        guard let value = readProperty(key, from: service) else { return nil }
        if let i = value as? Int { return i }
        if let n = value as? NSNumber { return n.intValue }
        return nil
    }
}
