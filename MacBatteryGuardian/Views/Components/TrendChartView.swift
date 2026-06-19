// TrendChartView.swift
// Gráfica de línea compacta para mostrar tendencias históricas con Swift Charts.

import SwiftUI
import Charts

struct TrendChartView: View {

    let data: [Double]
    let color: Color
    let yMin: Double
    let yMax: Double

    private struct DataPoint: Identifiable {
        let id: Int
        let value: Double
    }

    private var chartData: [DataPoint] {
        data.enumerated().map { DataPoint(id: $0.offset, value: $0.element) }
    }

    var body: some View {
        Chart(chartData) { point in
            LineMark(
                x: .value("Muestra", point.id),
                y: .value("Valor", point.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Muestra", point.id),
                y: .value("Valor", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yMin...yMax)
        .chartXScale(domain: 0...max(Double(data.count - 1), 1))
    }
}

#Preview {
    TrendChartView(
        data: [10, 15, 12, 20, 18, 25, 22, 19, 24, 28],
        color: .blue,
        yMin: 0,
        yMax: 100
    )
    .frame(height: 80)
    .padding()
}
