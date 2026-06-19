// CPUTabView.swift
// Pestaña de CPU: uso actual, cronología y procesos.

import SwiftUI
import Charts

struct CPUTabView: View {

    @EnvironmentObject private var store: ViewModelStore

    var body: some View {
        let vm = store.cpu

        VStack(spacing: 20) {
            MetricCardView(title: "Uso de CPU", icon: "cpu", iconColor: .blue) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 20) {
                            DetailStatBlock(label: "Total", value: vm.totalUsage, color: .blue)
                            DetailStatBlock(label: "Usuario", value: vm.userUsage, color: .indigo)
                            DetailStatBlock(label: "Sistema", value: vm.systemUsage, color: .cyan)
                        }

                        Divider()

                        Text("Evolución en el tiempo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TimelineChartView(
                            samples: vm.cpuTimeline,
                            color: .blue,
                            yMin: 0,
                            yMax: 100
                        )
                    }
                }

                MetricCardView(title: "Núcleos Apple Silicon", icon: "memorychip", iconColor: .gray) {
                    HStack(spacing: 16) {
                        coreCell(label: "P-Cores", count: vm.performanceCores,
                                 subtitle: "Rendimiento", color: .blue)
                        coreCell(label: "E-Cores", count: vm.efficiencyCores,
                                 subtitle: "Eficiencia", color: .green)
                    }
                }

                MetricCardView(title: "Estado térmico", icon: "thermometer.medium", iconColor: vm.thermalColor) {
                    HStack(spacing: 16) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 36))
                            .foregroundStyle(vm.thermalColor)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(vm.thermalState.localizedDescription)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(vm.thermalColor)
                            Text("Estado reportado por el sistema (ProcessInfo.ThermalState)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                MetricCardView(title: "Procesos por impacto energético", icon: "list.number", iconColor: .orange) {
                    VStack(spacing: 6) {
                        ForEach(vm.topProcesses.prefix(8)) { process in
                            ProcessRowView(process: process, compact: false)
                            if process.id != vm.topProcesses.prefix(8).last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(20)
    }

    private func coreCell(label: String, count: Int, subtitle: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .liquidGlassInset(cornerRadius: LiquidGlassTokens.insetRadius)
    }
}
