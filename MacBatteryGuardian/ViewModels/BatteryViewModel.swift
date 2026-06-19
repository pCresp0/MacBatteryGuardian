// BatteryViewModel.swift
// ViewModel para la pestaña de Batería en la ventana principal.

import Foundation
import SwiftUI

@MainActor
final class BatteryViewModel: ObservableObject {

    @Published private(set) var percentage: Int = 0
    @Published private(set) var maxCapacityFormatted: String = "–"
    @Published private(set) var designCapacityFormatted: String = "–"
    @Published private(set) var healthPercentFormatted: String = "–"
    @Published private(set) var healthCondition: BatteryHealthCondition = .unknown
    @Published private(set) var healthColor: Color = .gray
    @Published private(set) var cycleCount: Int = 0
    @Published private(set) var cycleWarningVisible: Bool = false
    @Published private(set) var isPluggedIn: Bool = false
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var isFullyCharged: Bool = false
    @Published private(set) var timeToEmptyFormatted: String = "–"
    @Published private(set) var timeToFullFormatted: String = "–"

    // MARK: - Consumo

    @Published private(set) var rate15min: String = "–"
    @Published private(set) var rate30min: String = "–"
    @Published private(set) var rate1h: String = "–"
    @Published private(set) var rate3h: String = "–"
    @Published private(set) var trend: ConsumptionTrend = .unknown
    @Published private(set) var autonomyFormatted: String = "–"
    @Published private(set) var autonomySentence: String? = nil
    @Published private(set) var depletionSentence: String? = nil
    @Published private(set) var alertState: ConsumptionAlertState = .stable
    @Published private(set) var alertColor: Color = .green

    /// Cronología de batería (últimas 12 h) con estado de carga.
    @Published private(set) var batteryChartPoints: [BatteryTimelinePoint] = []
    @Published private(set) var batteryPluggedInIntervals: [DateInterval] = []
    @Published private(set) var batteryChargingIntervals: [DateInterval] = []
    /// Consumo %/h en el tiempo (cuando hay dato).
    @Published private(set) var consumptionTimeline: [TimelineSample] = []
    private let maxTimelinePoints = 120
    private var liveBatteryPoints: [BatteryTimelinePoint] = []
    private let historyRepository = HistoryRepository.shared
    private var chartRefreshTask: Task<Void, Never>?

    // MARK: - Actualización

    func update(snapshot: BatterySnapshot?, metrics: EnergyMetrics?) {
        guard let battery = snapshot else { return }

        percentage = battery.percentage
        maxCapacityFormatted = battery.maxCapacityMAh > 0
            ? "\(battery.maxCapacityMAh) mAh"
            : "–"
        designCapacityFormatted = battery.designCapacityMAh.map { "\($0) mAh" } ?? "–"

        if let health = battery.healthPercentage {
            healthPercentFormatted = String(format: "%.0f %%", health)
            healthColor = health >= 90 ? .green : health >= 80 ? .yellow : .red
        } else {
            healthPercentFormatted = battery.healthCondition.localizedDescription
            healthColor = battery.healthCondition == .good ? .green :
                          battery.healthCondition == .fair ? .yellow : .red
        }

        healthCondition = battery.healthCondition
        cycleCount = battery.cycleCount
        cycleWarningVisible = battery.cycleCount >= Constants.Battery.warnCycles

        isPluggedIn = battery.isPluggedIn
        isCharging  = battery.isCharging
        isFullyCharged = battery.isFullyCharged

        if let minutes = battery.timeToEmptyMinutes {
            let h = minutes / 60; let m = minutes % 60
            timeToEmptyFormatted = h > 0 ? "\(h) h \(m) min" : "\(m) min"
        } else {
            timeToEmptyFormatted = "–"
        }

        if let minutes = battery.timeToFullMinutes {
            let h = minutes / 60; let m = minutes % 60
            timeToFullFormatted = h > 0 ? "\(h) h \(m) min" : "\(m) min"
        } else {
            timeToFullFormatted = "–"
        }

        if let m = metrics {
            rate15min         = m.ratePerHour15min.map { String(format: "%.1f %%/h", $0) } ?? "–"
            rate30min         = m.ratePerHour30min.map { String(format: "%.1f %%/h", $0) } ?? "–"
            rate1h            = m.ratePerHour1h.map    { String(format: "%.1f %%/h", $0) } ?? "–"
            rate3h            = m.ratePerHour3h.map    { String(format: "%.1f %%/h", $0) } ?? "–"
            trend             = m.trend
            autonomyFormatted = m.estimatedAutonomyFormatted
            alertState        = m.alertState
            alertColor        = .alertStateColor(m.alertState)

            if !battery.isPluggedIn {
                let minutes = m.estimatedAutonomyMinutes
                    ?? battery.timeToEmptyMinutes.flatMap { $0 > 0 ? $0 : nil }
                autonomySentence = minutes.map { Date.batteryAutonomySentence(minutes: $0) }
                let depletion: Date? = {
                    if m.hasEnoughRateData,
                       let fromRate = m.estimatedDepletionDate(batteryPercentage: battery.percentage) {
                        return fromRate
                    }
                    return minutes.flatMap { Date.batteryDepletionEstimate(fromMinutes: $0) }
                }()
                depletionSentence = depletion?.batteryDepletionSentence
            } else {
                autonomySentence = nil
                depletionSentence = nil
            }

            if let rate = m.averageRatePerHour {
                TimelineHistory.append(rate, to: &consumptionTimeline, maxPoints: maxTimelinePoints)
            }
        } else {
            autonomySentence = nil
            depletionSentence = nil
        }

        appendLiveBatteryPoint(from: battery)
        scheduleBatteryChartRefresh()
    }

    func reloadBatteryChart() async {
        await refreshBatteryChart()
    }

    // MARK: - Cronología 12 h

    private func appendLiveBatteryPoint(from battery: BatterySnapshot) {
        liveBatteryPoints.append(BatteryTimelinePoint.from(snapshot: battery))
        let cutoff = BatteryTimelineChart.windowStart()
        liveBatteryPoints = liveBatteryPoints.filter { $0.date >= cutoff }
    }

    private func scheduleBatteryChartRefresh() {
        chartRefreshTask?.cancel()
        chartRefreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await self?.refreshBatteryChart()
        }
    }

    private func refreshBatteryChart() async {
        let cutoff = BatteryTimelineChart.windowStart()
        let historical = await historyRepository.fetchSince(cutoff)
        let merged = BatteryTimelineBuilder.merge(historical: historical, live: liveBatteryPoints)
        batteryChartPoints = merged
        batteryPluggedInIntervals = BatteryTimelineBuilder.pluggedInIntervals(from: merged)
        batteryChargingIntervals = BatteryTimelineBuilder.chargingIntervals(from: merged)
    }
}
