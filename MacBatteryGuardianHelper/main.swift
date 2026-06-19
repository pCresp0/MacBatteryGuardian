// main.swift
// Punto de entrada del helper privilegiado MacBatteryGuardianHelper.
// Se registra como servicio XPC de launchd y espera conexiones de la app principal.

import Foundation
import OSLog

let logger = Logger(subsystem: "com.macbatteryguardian.helper", category: "Main")
logger.info("MacBatteryGuardianHelper arrancando.")

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: "com.macbatteryguardian.helper")
listener.delegate = delegate
listener.resume()

logger.info("MacBatteryGuardianHelper escuchando en Mach service.")

// Mantener el helper en ejecución indefinidamente
RunLoop.main.run()
