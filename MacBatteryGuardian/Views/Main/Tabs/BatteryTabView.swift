// BatteryTabView.swift
// Pestaña de Batería: información detallada, cronología y salud.

import SwiftUI

struct BatteryTabView: View {

    @EnvironmentObject private var store: ViewModelStore

    private let chartHeight: CGFloat = 96

    var body: some View {
        let vm = store.battery

        VStack(spacing: 12) {
            heroCard(vm: vm)
            timelineCard(vm: vm)
            consumptionSection(vm: vm)
            batteryHealthCard(vm: vm)
        }
        .padding(16)
    }

    // MARK: - Hero

    private func heroCard(vm: BatteryViewModel) -> some View {
        MetricCardView(title: "Estado actual", icon: "battery.100", iconColor: .green) {
            HStack(alignment: .center, spacing: 16) {
                BatteryArcView(
                    percentage: vm.percentage,
                    isCharging: vm.isCharging,
                    isPluggedIn: vm.isPluggedIn
                )
                .frame(width: 88, height: 88)

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(vm.percentage)%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.batteryColor(percentage: vm.percentage))

                    Group {
                        if vm.isCharging {
                            Label("Cargando · \(vm.timeToFullFormatted)", systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if vm.isPluggedIn {
                            if vm.isFullyCharged || vm.percentage >= 99 {
                                Label("Conectado — batería completa", systemImage: "bolt.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Label("Conectado al cargador — carga en pausa", systemImage: "bolt.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            BatteryAutonomySummaryView(
                                autonomySentence: vm.autonomySentence,
                                depletionSentence: vm.depletionSentence
                            )
                        }
                    }

                    HStack(spacing: 20) {
                        DetailStatBlock(
                            label: "Estado consumo",
                            value: vm.alertState.localizedTitle,
                            color: vm.alertColor,
                            compact: true
                        )
                        DetailStatBlock(
                            label: "Tendencia",
                            value: vm.trend.localizedDescription,
                            color: .secondary,
                            compact: true
                        )
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Cronología

    private func timelineCard(vm: BatteryViewModel) -> some View {
        MetricCardView(title: "Nivel de batería en el tiempo", icon: "chart.xyaxis.line", iconColor: .green) {
            TimelineChartView(
                samples: vm.batteryTimeline,
                color: .green,
                yMin: 0,
                yMax: 100,
                detailedHeight: chartHeight
            )
        }
    }

    // MARK: - Consumo

    private func consumptionSection(vm: BatteryViewModel) -> some View {
        VStack(spacing: 12) {
            MetricCardView(title: "Consumo energético (%/h)", icon: "flame.fill", iconColor: vm.alertColor) {
                VStack(alignment: .leading, spacing: 8) {
                    TimelineChartView(
                        samples: vm.consumptionTimeline,
                        color: vm.alertColor,
                        yMin: 0,
                        yMax: max(30, (vm.consumptionTimeline.map(\.value).max() ?? 20) * 1.2),
                        valueFormat: "%.0f",
                        detailedHeight: chartHeight
                    )

                    Text(vm.alertState.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            MetricCardView(title: "Media por ventana temporal", icon: "clock.arrow.circlepath", iconColor: .orange) {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    DetailMetricPill(title: "15 min", value: vm.rate15min, tint: .orange, compact: true)
                    DetailMetricPill(title: "30 min", value: vm.rate30min, tint: .orange, compact: true)
                    DetailMetricPill(title: "1 hora", value: vm.rate1h, tint: .orange, compact: true)
                    DetailMetricPill(title: "3 horas", value: vm.rate3h, tint: .orange, compact: true)
                }
            }
        }
    }

    // MARK: - Salud

    private func batteryHealthCard(vm: BatteryViewModel) -> some View {
        MetricCardView(title: "Salud de la batería", icon: "heart.fill", iconColor: vm.healthColor) {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                DetailStatBlock(label: "Capacidad actual", value: vm.maxCapacityFormatted, compact: true)
                DetailStatBlock(label: "Capacidad original", value: vm.designCapacityFormatted, compact: true)
                DetailStatBlock(label: "Salud", value: vm.healthPercentFormatted, color: vm.healthColor, compact: true)
                DetailStatBlock(
                    label: "Ciclos de carga",
                    value: "\(vm.cycleCount)",
                    color: vm.cycleWarningVisible ? .yellow : .primary,
                    footnote: vm.cycleWarningVisible ? "Muchos ciclos acumulados" : nil,
                    compact: true
                )
            }
        }
    }
}
