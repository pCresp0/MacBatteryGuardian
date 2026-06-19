// RecommendationCardView.swift
// Tarjeta que muestra una recomendación del HealthScoreManager con nivel de severidad.

import SwiftUI

struct RecommendationCardView: View {

    let recommendation: HealthRecommendation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severityIcon)
                .foregroundStyle(severityColor)
                .font(.system(size: 18))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(recommendation.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassInset(cornerRadius: LiquidGlassTokens.compactRadius)
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlassTokens.compactRadius, style: .continuous)
                .strokeBorder(severityColor.opacity(0.28), lineWidth: 0.75)
        }
    }

    private var severityIcon: String {
        switch recommendation.severity {
        case .high:   return "exclamationmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .low:    return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch recommendation.severity {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .blue
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        RecommendationCardView(recommendation: HealthRecommendation(
            title: "Chrome utiliza demasiada CPU",
            detail: "Google Chrome lleva más de 30 minutos consumiendo más del 15% de CPU.",
            severity: .medium,
            category: .process
        ))
        RecommendationCardView(recommendation: HealthRecommendation(
            title: "Reinicio recomendado",
            detail: "El equipo lleva más de 7 días encendido.",
            severity: .low,
            category: .uptime
        ))
    }
    .padding()
}
