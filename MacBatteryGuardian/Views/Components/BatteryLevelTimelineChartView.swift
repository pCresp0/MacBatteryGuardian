// BatteryLevelTimelineChartView.swift
// Cronología de batería (12 h) con bandas de carga al estilo Ajustes de macOS.

import SwiftUI
import Charts

struct BatteryLevelTimelineChartView: View {

    let points: [BatteryTimelinePoint]
    let pluggedInIntervals: [DateInterval]
    let chargingIntervals: [DateInterval]
    var chartHeight: CGFloat = 108

    @State private var hoverDate: Date?

    private var windowStart: Date { BatteryTimelineChart.windowStart() }
    private var windowEnd: Date { Date() }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if points.count >= 2 {
                batteryChart
                    .frame(height: chartHeight)
                ChargingTimelineStrip(
                    pluggedInIntervals: pluggedInIntervals,
                    chargingIntervals: chargingIntervals,
                    windowStart: windowStart,
                    windowEnd: windowEnd
                )
                .frame(height: 18)
            } else {
                emptyPlaceholder
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let hoverDate, let point = resolvedPoint(for: hoverDate) {
                    Text(hoverSummary(for: point))
                        .font(.caption)
                        .foregroundStyle(.primary)
                } else {
                    Text(BatteryTimelineBuilder.footerDescription(for: points))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if !chargingIntervals.isEmpty, hoverDate == nil {
                    Label("Cargando", systemImage: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    @ViewBuilder
    private var batteryChart: some View {
        Chart {
            ForEach(pluggedInIntervals, id: \.self) { interval in
                RectangleMark(
                    xStart: .value("Desde", clampedStart(interval.start)),
                    xEnd: .value("Hasta", clampedEnd(interval.end)),
                    yStart: .value("Min", 0),
                    yEnd: .value("Max", 100)
                )
                .foregroundStyle(Color.green.opacity(0.09))
            }

            ForEach(points) { point in
                AreaMark(
                    x: .value("Hora", point.date),
                    y: .value("Nivel", point.level)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green.opacity(0.32), Color.green.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.stepEnd)
            }

            ForEach(points) { point in
                LineMark(
                    x: .value("Hora", point.date),
                    y: .value("Nivel", point.level)
                )
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.stepEnd)
            }
        }
        .chartXScale(domain: windowStart...windowEnd)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.22))
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 50, 100]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.22))
                if let level = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(level)) %")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            chartHoverOverlay(proxy: proxy)
        }
    }

    @ViewBuilder
    private func chartHoverOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                if let hoverDate,
                   let point = resolvedPoint(for: hoverDate),
                   let plotX = proxy.position(forX: hoverDate),
                   let plotY = proxy.position(forY: point.level) {

                    Path { path in
                        path.move(to: CGPoint(x: plotX, y: 0))
                        path.addLine(to: CGPoint(x: plotX, y: geometry.size.height))
                    }
                    .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.22))
                            .frame(width: 14, height: 14)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                    }
                    .position(x: plotX, y: plotY)

                    hoverCallout(for: point)
                        .position(
                            x: min(max(plotX, 72), geometry.size.width - 72),
                            y: 18
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverDate = proxy.value(atX: location.x, as: Date.self)
                case .ended:
                    hoverDate = nil
                }
            }
        }
    }

    private func hoverCallout(for point: BatteryTimelinePoint) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(point.date, format: .dateTime.hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text("\(Int(point.level.rounded())) %")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(chargeStateLabel(for: point))
                    .font(.caption2)
                    .foregroundStyle(chargeStateColor(for: point))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
        }
    }

    private func hoverSummary(for point: BatteryTimelinePoint) -> String {
        let time = point.date.formatted(.dateTime.hour().minute())
        let level = Int(point.level.rounded())
        return "\(time) · \(level) % · \(chargeStateLabel(for: point))"
    }

    /// Valor en un instante con interpolación «step» (como la gráfica).
    private func resolvedPoint(for date: Date) -> BatteryTimelinePoint? {
        let sorted = points.sorted { $0.date < $1.date }
        return sorted.last(where: { $0.date <= date }) ?? sorted.first
    }

    private func chargeStateLabel(for point: BatteryTimelinePoint) -> String {
        if point.isCharging { return "Cargando" }
        if point.isPluggedIn { return "Enchufado" }
        return "En batería"
    }

    private func chargeStateColor(for point: BatteryTimelinePoint) -> Color {
        if point.isCharging { return .green }
        if point.isPluggedIn { return .secondary }
        return .secondary
    }

    @ViewBuilder
    private var emptyPlaceholder: some View {
        Color.clear
            .frame(height: chartHeight + 18)
            .liquidGlassInset(cornerRadius: 8)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundStyle(Color.green.opacity(0.5))
                    Text("Esperando más lecturas…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Se mostrarán las últimas 12 horas")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
    }

    private func clampedStart(_ date: Date) -> Date {
        max(date, windowStart)
    }

    private func clampedEnd(_ date: Date) -> Date {
        min(date, windowEnd)
    }
}

// MARK: - Franja de carga (estilo macOS)

private struct ChargingTimelineStrip: View {
    let pluggedInIntervals: [DateInterval]
    let chargingIntervals: [DateInterval]
    let windowStart: Date
    let windowEnd: Date

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let midY = geometry.size.height / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .position(x: width / 2, y: midY)

                ForEach(pluggedInIntervals, id: \.self) { interval in
                    let frame = xFrame(for: interval, totalWidth: width)
                    Capsule()
                        .fill(Color.green.opacity(0.85))
                        .frame(width: max(frame.width, 3), height: 2)
                        .position(x: frame.midX, y: midY)
                }

                ForEach(chargingIntervals, id: \.self) { interval in
                    let frame = xFrame(for: interval, totalWidth: width)
                    if frame.width >= 10 {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                            .position(x: frame.midX, y: midY)
                    }
                }
            }
        }
    }

    private func xFrame(for interval: DateInterval, totalWidth: CGFloat) -> (midX: CGFloat, width: CGFloat) {
        let span = windowEnd.timeIntervalSince(windowStart)
        guard span > 0 else { return (0, 0) }

        let start = max(interval.start, windowStart)
        let end = min(interval.end, windowEnd)
        guard end > start else { return (0, 0) }

        let xStart = CGFloat(start.timeIntervalSince(windowStart) / span) * totalWidth
        let xEnd = CGFloat(end.timeIntervalSince(windowStart) / span) * totalWidth
        let width = xEnd - xStart
        return (xStart + width / 2, width)
    }
}
