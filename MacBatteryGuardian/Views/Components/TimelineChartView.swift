// TimelineChartView.swift
// Gráfica con eje horizontal de tiempo que crece según llegan muestras.

import SwiftUI
import Charts

struct TimelineChartView: View {

    enum Style {
        /// Eje temporal completo (pestañas de detalle).
        case detailed
        /// Eje temporal sin eje Y (tarjetas resumen en General).
        case summary
        /// Mini sparkline sin ejes.
        case compact
    }

    let samples: [TimelineSample]
    let color: Color
    let yMin: Double
    let yMax: Double
    let valueFormat: String
    var style: Style = .detailed
    /// Altura de la gráfica en modo `.detailed` (por defecto 140 pt).
    var detailedHeight: CGFloat = 140

    init(
        samples: [TimelineSample],
        color: Color,
        yMin: Double = 0,
        yMax: Double = 100,
        valueFormat: String = "%.0f%%",
        style: Style = .detailed,
        detailedHeight: CGFloat = 140
    ) {
        self.samples = samples
        self.color = color
        self.yMin = yMin
        self.yMax = yMax
        self.valueFormat = valueFormat
        self.style = style
        self.detailedHeight = detailedHeight
    }

    private var chartHeight: CGFloat {
        switch style {
        case .compact: return 32
        case .summary: return 72
        case .detailed: return detailedHeight
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: style == .compact ? 0 : 6) {
            if samples.count >= 2 {
                chartContent
                    .frame(height: chartHeight)
            } else {
                emptyPlaceholder
            }

            if style == .detailed || style == .summary {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(TimelineHistory.spanDescription(for: samples))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        Chart(samples) { sample in
            LineMark(
                x: .value("Hora", sample.date),
                y: .value("Valor", sample.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)

            if style == .detailed || style == .summary {
                AreaMark(
                    x: .value("Hora", sample.date),
                    y: .value("Valor", sample.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.28), color.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: yMin...yMax)
        .chartXAxis(style == .compact ? .hidden : .automatic)
        .chartYAxis(style == .detailed ? .automatic : .hidden)
        .if(style == .detailed || style == .summary) { view in
            view
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: style == .summary ? 3 : 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.secondary.opacity(0.25))
                        AxisValueLabel(format: .dateTime.hour().minute())
                            .font(.caption2)
                    }
                }
        }
        .if(style == .detailed) { view in
            view
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.secondary.opacity(0.25))
                        if let v = value.as(Double.self) {
                            AxisValueLabel {
                                Text(String(format: valueFormat, v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var emptyPlaceholder: some View {
        Color.clear
            .frame(height: chartHeight)
            .liquidGlassInset(cornerRadius: 8)
            .overlay {
                if style == .detailed || style == .summary {
                    VStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(style == .summary ? .title3 : .title2)
                            .foregroundStyle(color.opacity(0.5))
                        Text("Esperando más lecturas…")
                            .font(style == .summary ? .caption : .subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
    }
}

// MARK: - View helper

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
