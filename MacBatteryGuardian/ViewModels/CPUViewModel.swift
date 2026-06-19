// CPUViewModel.swift
// ViewModel para la pestaña de CPU en la ventana principal.

import Foundation
import SwiftUI

@MainActor
final class CPUViewModel: ObservableObject {

    @Published private(set) var totalUsage: String = "–"
    @Published private(set) var userUsage: String  = "–"
    @Published private(set) var systemUsage: String = "–"
    @Published private(set) var performanceCores: Int = 0
    @Published private(set) var efficiencyCores: Int = 0
    @Published private(set) var thermalState: SystemThermalState = .nominal
    @Published private(set) var thermalColor: Color = .green
    @Published private(set) var topProcesses: [ProcessSnapshot] = []

    // Historial en vivo para gráfica temporal
    @Published private(set) var cpuTimeline: [TimelineSample] = []
    private let maxTimelinePoints = 120

    func update(system: SystemSnapshot?, processes: [ProcessSnapshot]) {
        guard let system else { return }

        totalUsage  = system.cpuUsagePercent.cpuUsageFormatted
        userUsage   = system.cpuUserPercent.cpuUsageFormatted
        systemUsage = system.cpuSystemPercent.cpuUsageFormatted

        performanceCores = system.performanceCoreCount
        efficiencyCores  = system.efficiencyCoreCount

        thermalState = system.thermalState
        thermalColor = .thermalStateColor(system.thermalState)

        topProcesses = Array(processes.prefix(8))

        TimelineHistory.append(system.cpuUsagePercent, to: &cpuTimeline, maxPoints: maxTimelinePoints)
    }
}
