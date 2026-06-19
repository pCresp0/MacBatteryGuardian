// HealthScoreBarView.swift
// Puntuación de salud en barra horizontal — no usa arco circular (evita confusión con batería).

import SwiftUI

struct HealthScoreBarView: View {

    let score: Int
    let color: Color
    let levelTitle: String

    private var progress: Double { Double(score) / 100.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("/ 100")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(levelTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: max(8, geo.size.width * progress))
                }
            }
            .frame(height: 10)
        }
    }
}
