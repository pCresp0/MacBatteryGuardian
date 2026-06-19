// HistoryTabView.swift
// Pestaña de Histórico: gráficas de evolución y estadísticas del período seleccionado.

import SwiftUI
import Charts

struct HistoryTabView: View {

    @EnvironmentObject private var store: ViewModelStore

    var body: some View {
        let vm = store.history

        VStack(spacing: 0) {
            // Selector de período
            Picker("Período", selection: Binding(
                get: { vm.selectedPeriod },
                set: { period in
                    Task { await vm.changePeriod(period) }
                }
            )) {
                ForEach(HistoryViewModel.HistoryPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .liquidGlassChrome(interactive: false)
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if vm.isLoading {
                ProgressView("Cargando historial...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
            } else if vm.records.isEmpty {
                emptyState
            } else {
                VStack(spacing: 16) {
                    statsCard(vm: vm)
                        .padding(.horizontal)

                    batteryChart(records: vm.records)
                        .padding(.horizontal)

                    consumptionChart(records: vm.records)
                        .padding(.horizontal)

                    cpuChart(records: vm.records, period: vm.selectedPeriod)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .task {
            await vm.loadRecordsIfNeeded()
        }
    }

    // MARK: - Componentes

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Sin datos para este período")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Los datos aparecerán tras los primeros ciclos de monitorización.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal)
    }

    private func statsCard(vm: HistoryViewModel) -> some View {
        MetricCardView(title: "Estadísticas del período", icon: "chart.bar", iconColor: .blue) {
            HStack(spacing: 0) {
                statCell(label: "Consumo medio", value: vm.averageRate)
                Divider().frame(height: 40)
                statCell(label: "Consumo máximo", value: vm.maxRate)
                Divider().frame(height: 40)
                statCell(label: "Batería mínima", value: vm.minBatteryLevel)
                Divider().frame(height: 40)
                statCell(label: "Registros", value: "\(vm.records.count)")
            }
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline).fontWeight(.semibold)
            Text(label)
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func batteryChart(records: [HistoricalRecord]) -> some View {
        MetricCardView(title: "Nivel de batería", icon: "battery.75", iconColor: .green) {
            Chart(records) { record in
                LineMark(
                    x: .value("Tiempo", record.timestamp),
                    y: .value("Batería", record.batteryPercentage)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Tiempo", record.timestamp),
                    y: .value("Batería", record.batteryPercentage)
                )
                .foregroundStyle(.green.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 120)
        }
    }

    private func consumptionChart(records: [HistoricalRecord]) -> some View {
        let rateRecords = records.filter { $0.ratePerHour != nil }
        return MetricCardView(title: "Consumo energético (%/h)", icon: "flame", iconColor: .orange) {
            if rateRecords.isEmpty {
                Text("Sin datos de consumo")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(height: 80)
            } else {
                Chart(rateRecords) { record in
                    if let rate = record.ratePerHour {
                        LineMark(
                            x: .value("Tiempo", record.timestamp),
                            y: .value("Consumo", rate)
                        )
                        .foregroundStyle(.orange)
                    }
                }
                .frame(height: 100)
            }
        }
    }

    private func cpuChart(
        records: [HistoricalRecord],
        period: HistoryViewModel.HistoryPeriod
    ) -> some View {
        let bucketed = Self.bucketedCPUBars(from: records, period: period)

        return MetricCardView(title: "Uso de CPU", icon: "cpu", iconColor: .blue) {
            if bucketed.bars.allSatisfy({ !$0.hasData }) {
                Text("Sin datos de CPU")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(height: 80)
            } else {
                Chart(bucketed.bars) { bar in
                    BarMark(
                        x: .value("Tiempo", bar.timestamp),
                        y: .value("CPU", bar.value),
                        width: .ratio(0.72)
                    )
                    .foregroundStyle(bar.hasData ? Color.blue.opacity(0.85) : Color.blue.opacity(0.12))
                    .cornerRadius(2)
                }
                .chartYScale(domain: 0...100)
                .chartXScale(domain: bucketed.domain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: period == .today ? 6 : 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.25))
                        AxisValueLabel(format: period == .today ? .dateTime.hour().minute() : .dateTime.month().day())
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.secondary.opacity(0.25))
                        if let v = value.as(Double.self) {
                            AxisValueLabel {
                                Text(String(format: "%.0f", v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 120)
            }
        }
    }

    /// Agrupa registros en intervalos uniformes para barras equidistantes (sin solapamiento).
    private static func bucketedCPUBars(
        from records: [HistoricalRecord],
        period: HistoryViewModel.HistoryPeriod
    ) -> (bars: [CPUChartBar], domain: ClosedRange<Date>) {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let rangeStart: Date
        let bucketCount: Int
        switch period {
        case .today:
            rangeStart = startOfToday
            bucketCount = 24
        case .week:
            rangeStart = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
            bucketCount = 7
        case .month:
            rangeStart = calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday
            bucketCount = 30
        }

        let rangeEnd = now
        let totalInterval = max(rangeEnd.timeIntervalSince(rangeStart), 60)
        let bucketDuration = totalInterval / Double(bucketCount)

        let bars: [CPUChartBar] = (0..<bucketCount).map { index in
            let bucketStart = rangeStart.addingTimeInterval(Double(index) * bucketDuration)
            let bucketEnd = bucketStart.addingTimeInterval(bucketDuration)
            let bucketMid = bucketStart.addingTimeInterval(bucketDuration / 2)

            let inBucket: [HistoricalRecord]
            if index == bucketCount - 1 {
                inBucket = records.filter { $0.timestamp >= bucketStart && $0.timestamp <= rangeEnd }
            } else {
                inBucket = records.filter { $0.timestamp >= bucketStart && $0.timestamp < bucketEnd }
            }

            let average = inBucket.isEmpty
                ? 0
                : inBucket.map(\.cpuUsagePercent).reduce(0, +) / Double(inBucket.count)

            return CPUChartBar(
                id: index,
                timestamp: bucketMid,
                value: average,
                hasData: !inBucket.isEmpty
            )
        }

        return (bars, rangeStart...rangeEnd)
    }
}

private struct CPUChartBar: Identifiable {
    let id: Int
    let timestamp: Date
    let value: Double
    let hasData: Bool
}
