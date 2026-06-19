// HealthTabView.swift
// Pestaña de Salud del Mac: índice global, factores y recomendaciones.

import SwiftUI

struct HealthTabView: View {

    @EnvironmentObject private var store: ViewModelStore

    var body: some View {
        let vm = store.health

        VStack(spacing: 16) {
            scoreCard(vm: vm)
            factorsCard(vm: vm)

            if !vm.recommendations.isEmpty {
                MetricCardView(title: "Recomendaciones", icon: "lightbulb.fill", iconColor: .orange) {
                    VStack(spacing: 10) {
                        ForEach(vm.recommendations) { rec in
                            RecommendationCardView(recommendation: rec)
                        }
                    }
                }
            }

            if !vm.topCulprits.isEmpty {
                MetricCardView(
                    title: "Apps con mayor impacto",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange
                ) {
                    VStack(spacing: 6) {
                        ForEach(vm.topCulprits) { process in
                            ProcessRowView(process: process, compact: false)
                            if process.id != vm.topCulprits.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
    }

    // MARK: - Tarjetas

    private func scoreCard(vm: HealthViewModel) -> some View {
        MetricCardView(title: "Índice de salud del Mac", icon: "heart.fill", iconColor: vm.scoreColor) {
            VStack(alignment: .leading, spacing: 12) {
                HealthScoreBarView(
                    score: vm.score,
                    color: vm.scoreColor,
                    levelTitle: vm.level.localizedTitle
                )

                HStack(spacing: 6) {
                    if vm.recommendations.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Todos los factores dentro de lo normal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text("\(vm.recommendations.count) recomendación\(vm.recommendations.count == 1 ? "" : "es") activa\(vm.recommendations.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func factorsCard(vm: HealthViewModel) -> some View {
        MetricCardView(title: "Factores del índice", icon: "chart.bar.fill", iconColor: .secondary) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cada barra muestra cuánto resta ese factor al índice (más llena = más impacto).")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    ForEach(vm.healthFactors) { factor in
                        HealthFactorCard(
                            icon: factor.icon,
                            label: factor.label,
                            penalty: factor.penalty,
                            maxPenalty: factor.maxPenalty,
                            tint: factor.tint
                        )
                    }
                }
            }
        }
    }
}
