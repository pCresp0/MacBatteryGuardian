// PowerMode.swift
// Representa el modo de energía actual del sistema y su origen.

import Foundation

/// Modo de energía del sistema.
enum PowerMode: String, Codable, Sendable, Equatable {
    /// Funcionamiento normal, sin restricciones.
    case normal     = "normal"
    /// Modo de bajo consumo activo.
    case lowPower   = "lowPower"

    var localizedTitle: String {
        switch self {
        case .normal:   return "Modo Normal"
        case .lowPower: return "Modo Bajo Consumo"
        }
    }

    var sfSymbolName: String {
        switch self {
        case .normal:   return "bolt.circle"
        case .lowPower: return "leaf.circle.fill"
        }
    }
}

/// Describe el origen de un cambio de modo de energía.
enum PowerModeSource: String, Codable, Sendable {
    /// El usuario lo activó manualmente desde la app.
    case manual    = "manual"
    /// Lo activó el motor automático de la app.
    case automatic = "automatic"
    /// Lo activó el propio sistema operativo.
    case system    = "system"
}

/// Estado completo del modo de energía incluyendo su origen.
struct PowerModeState: Codable, Equatable, Sendable {
    let mode: PowerMode
    let source: PowerModeSource
    let activatedAt: Date?

    static let normal = PowerModeState(mode: .normal, source: .system, activatedAt: nil)
}
