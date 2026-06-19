// HealthFactorCard.swift
// Tarjeta compacta de un factor del índice de salud con barra de impacto.

import SwiftUI

struct HealthFactorCard: View {

    let icon: String
    let label: String
    let penalty: Double
    let maxPenalty: Double
    let tint: Color

    private var impactRatio: Double {
        guard maxPenalty > 0 else { return 0 }
        return min(1, penalty / maxPenalty)
    }

    private var impactColor: Color {
        switch impactRatio {
        case 0:           return .green
        case ..<0.35:     return .secondary
        case ..<0.65:     return .orange
        default:          return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 18)

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                Text(statusLabel)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(impactColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
                    if impactRatio > 0 {
                        Capsule()
                            .fill(impactColor)
                            .frame(width: max(4, geo.size.width * impactRatio))
                    }
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .liquidGlassInset(cornerRadius: LiquidGlassTokens.insetRadius)
    }

    private var statusLabel: String {
        if penalty <= 0 { return "OK" }
        return "-\(Int(penalty.rounded())) pts"
    }
}
