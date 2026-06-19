// MenuBarViewModel.swift
// ViewModel para el ícono de la barra de menú. Solo contiene los datos
// mínimos necesarios para mantener el overhead lo más bajo posible.

import Foundation
import SwiftUI

/// Datos para el ícono de la barra de menú: texto y color.
@MainActor
final class MenuBarViewModel: ObservableObject {

    // MARK: - Estado publicado

    @Published private(set) var title: String = ""
    @Published private(set) var titleColor: Color = .primary
    @Published private(set) var isPluggedIn: Bool = false
    @Published private(set) var lowPowerModeActive: Bool = false
    @Published private(set) var alertState: ConsumptionAlertState = .stable

    // MARK: - Actualización

    func update(
        battery: BatterySnapshot?,
        metrics: EnergyMetrics?,
        powerMode: PowerModeState
    ) {
        let settings = SettingsRepository.shared
        isPluggedIn = battery?.isPluggedIn ?? false
        lowPowerModeActive = powerMode.mode == .lowPower
        alertState = metrics?.alertState ?? .stable

        var parts: [String] = []

        let canShowRate = settings.showConsumptionRateInMenuBar
            && battery != nil
            && !isPluggedIn
            && metrics?.hasEnoughRateData == true
            && metrics?.averageRatePerHour != nil

        if canShowRate, let rate = metrics?.averageRatePerHour {
            parts.append(Self.formatRatePerHour(rate))
        } else if settings.showPercentageInMenuBar, let pct = battery?.percentage {
            parts.append("\(pct)%")
        }

        title = parts.joined(separator: " ")

        if !isPluggedIn, metrics?.hasEnoughRateData == true {
            titleColor = .alertStateColor(alertState)
        } else if let pct = battery?.percentage {
            titleColor = .batteryColor(percentage: pct)
        } else {
            titleColor = .primary
        }
    }

    /// Formato compacto para la barra de menú: "13%/h"
    private static func formatRatePerHour(_ rate: Double) -> String {
        if rate >= 10 {
            return String(format: "%.0f%%/h", rate)
        }
        return String(format: "%.1f%%/h", rate)
    }

    func syncPowerMode(_ state: PowerModeState) {
        lowPowerModeActive = state.mode == .lowPower
    }
}
