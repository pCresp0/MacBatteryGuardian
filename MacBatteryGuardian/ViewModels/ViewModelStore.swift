// ViewModelStore.swift
// Contenedor central de todos los ViewModels. Se inyecta como EnvironmentObject
// para que todas las vistas compartan el mismo estado actualizado.

import Foundation
import Combine

/// Contenedor de ViewModels que actúa como fuente única de verdad para la UI.
@MainActor
final class ViewModelStore: ObservableObject {

    // MARK: - ViewModels

    let menuBar    = MenuBarViewModel()
    let popover    = PopoverViewModel()
    let battery    = BatteryViewModel()
    let cpu        = CPUViewModel()
    let memory     = MemoryViewModel()
    let history    = HistoryViewModel()
    let health     = HealthViewModel()
    let settingsVM = SettingsViewModel()

    // MARK: - Actualización coordinada

    /// Actualiza todos los ViewModels con los datos del último ciclo de monitorización.
    func update(
        battery: BatterySnapshot?,
        system: SystemSnapshot?,
        processes: [ProcessSnapshot],
        metrics: EnergyMetrics?,
        health: HealthScore?,
        powerMode: PowerModeState
    ) {
        menuBar.update(battery: battery, metrics: metrics, powerMode: powerMode)
        popover.update(battery: battery, system: system, metrics: metrics, processes: processes, powerMode: powerMode)
        self.battery.update(snapshot: battery, metrics: metrics)
        cpu.update(system: system, processes: processes)
        memory.update(system: system)
        if let h = health { self.health.update(score: h, processes: processes) }
    }

    /// Propaga un cambio de modo de energía a la UI sin esperar al siguiente ciclo.
    func syncPowerMode(_ powerMode: PowerModeState) {
        popover.syncPowerMode(powerMode)
        menuBar.syncPowerMode(powerMode)
    }
}
