// HealthGaugeView.swift
// Indicador circular animado del índice de salud del Mac (0–100).

import SwiftUI

struct HealthGaugeView: View {

    let score: Int
    let color: Color

    private var progress: Double { Double(score) / 100.0 }

    var body: some View {
        ZStack {
            // Fondo completo
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 7)

            // Arco del score
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.7), value: progress)

            // Score central
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("/ 100")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        HealthGaugeView(score: 87, color: .green)
            .frame(width: 80, height: 80)
        HealthGaugeView(score: 64, color: .yellow)
            .frame(width: 80, height: 80)
        HealthGaugeView(score: 38, color: .red)
            .frame(width: 80, height: 80)
    }
    .padding()
}
