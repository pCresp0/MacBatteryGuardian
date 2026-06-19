// MacBatteryGuardianApp.swift
// Punto de entrada de la aplicación. Gestiona el ciclo de vida y la inyección de dependencias.

import SwiftUI

@main
struct MacBatteryGuardianApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // La ventana principal se gestiona desde AppDelegate mediante NSWindow.
        // Usamos Settings únicamente para la ventana de preferencias accesible desde menú.
        Settings {
            EmptyView()
        }
    }
}
