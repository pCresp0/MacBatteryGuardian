// MemoryTabView.swift
// Pestaña de Memoria: uso actual, cronología y desglose.

import SwiftUI
import Charts

struct MemoryTabView: View {

    @EnvironmentObject private var store: ViewModelStore

    var body: some View {
        let vm = store.memory

        VStack(spacing: 20) {
            MetricCardView(title: "Uso de memoria", icon: "memorychip", iconColor: .purple) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(vm.usedFormatted)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text("de \(vm.totalFormatted) instalada")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        DetailStatBlock(
                            label: "Presión",
                            value: vm.pressureLevel.localizedDescription,
                            color: vm.pressureColor
                        )
                    }

                    ProgressView(value: vm.pressureRatio)
                        .tint(vm.pressureColor)
                        .scaleEffect(x: 1, y: 1.4, anchor: .center)

                    Divider()

                    Text("Evolución en el tiempo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TimelineChartView(
                        samples: vm.memoryTimeline,
                        color: .purple,
                        yMin: 0,
                        yMax: 100
                    )
                }
            }

            MetricCardView(title: "Desglose", icon: "square.split.2x2", iconColor: .gray) {
                MemorySegmentedBarView(
                    totalFormatted: vm.totalFormatted,
                    usedFormatted: vm.usedFormatted,
                    segments: vm.memoryBarSegments
                )
            }
        }
        .padding(20)
    }
}
