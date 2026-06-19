// HistoryViewModel.swift
// ViewModel para la pestaña de Histórico. Carga y prepara registros para las gráficas.

import Foundation
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {

    @Published private(set) var records: [HistoricalRecord] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var selectedPeriod: HistoryPeriod = .today
    @Published private(set) var averageRate: String = "–"
    @Published private(set) var maxRate: String = "–"
    @Published private(set) var minBatteryLevel: String = "–"

    private let repository = HistoryRepository.shared

    enum HistoryPeriod: String, CaseIterable {
        case today   = "Hoy"
        case week    = "7 días"
        case month   = "30 días"

        var days: Int {
            switch self {
            case .today: return 1
            case .week:  return 7
            case .month: return 30
            }
        }
    }

    func loadRecords(for period: HistoryPeriod? = nil) async {
        let target = period ?? selectedPeriod
        selectedPeriod = target
        let isRefresh = period != nil
        if !isRefresh && !records.isEmpty {
            return
        }

        isLoading = records.isEmpty

        let loaded = await repository.fetchLast(days: target.days)
        records = loaded

        // Calcular estadísticas
        let rates = loaded.compactMap(\.ratePerHour)
        if !rates.isEmpty {
            averageRate = String(format: "%.1f %%/h", rates.reduce(0, +) / Double(rates.count))
            maxRate     = String(format: "%.1f %%/h", rates.max() ?? 0)
        } else {
            averageRate = "–"
            maxRate     = "–"
        }

        let minLevel = loaded.map(\.batteryPercentage).min()
        minBatteryLevel = minLevel.map { "\($0)%" } ?? "–"

        isLoading = false
    }

    func loadRecordsIfNeeded() async {
        guard records.isEmpty else { return }
        await loadRecords()
    }

    func changePeriod(_ period: HistoryPeriod) async {
        await loadRecords(for: period)
    }
}
