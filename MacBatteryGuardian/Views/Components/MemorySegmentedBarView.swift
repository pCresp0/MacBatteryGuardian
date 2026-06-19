// MemorySegmentedBarView.swift
// Barra segmentada de RAM al estilo Almacenamiento de macOS.

import SwiftUI

struct MemoryBarSegment: Identifiable, Equatable {
    let id: String
    let label: String
    let formatted: String
    let color: Color
    let fraction: Double
    /// Si es false, solo aparece en la leyenda (p. ej. desglose de "Disponible").
    var showInBar: Bool = true

    var isVisible: Bool { fraction > 0.001 }
}

struct MemorySegmentedBarView: View {

    let totalFormatted: String
    let usedFormatted: String
    let segments: [MemoryBarSegment]

    private var barSegments: [MemoryBarSegment] {
        segments.filter { $0.showInBar && $0.isVisible }
    }

    private var legendSegments: [MemoryBarSegment] {
        segments.filter { $0.id != "available" && $0.isVisible }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Memoria RAM")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("En uso: \(usedFormatted) de \(totalFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let width = geo.size.width
                let totalFraction = max(barSegments.map(\.fraction).reduce(0, +), 0.001)

                HStack(spacing: 1) {
                    ForEach(barSegments) { segment in
                        segmentView(
                            segment,
                            width: width * (segment.fraction / totalFraction)
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .frame(height: 30)

            legend
        }
    }

    @ViewBuilder
    private func segmentView(_ segment: MemoryBarSegment, width: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(segment.color)

            if (segment.id == "available" || segment.id == "free"), width > 52 {
                Text(segment.formatted)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(width: max(2, width))
        .accessibilityLabel("\(segment.label): \(segment.formatted)")
    }

    private var legend: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(legendSegments.filter { $0.id != "free" }) { segment in
                legendItem(segment)
            }
            if let free = legendSegments.first(where: { $0.id == "free" }) {
                legendItem(free)
            }
        }
    }

    private func legendItem(_ segment: MemoryBarSegment) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(segment.color)
                .frame(width: 8, height: 8)
            Text(segment.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(segment.formatted)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    MemorySegmentedBarView(
        totalFormatted: "24.00 GB",
        usedFormatted: "17.58 GB",
        segments: [
            MemoryBarSegment(id: "wired", label: "Bloqueada (Wired)", formatted: "3.23 GB", color: .red, fraction: 0.13),
            MemoryBarSegment(id: "compressed", label: "Comprimida", formatted: "8.64 GB", color: .orange, fraction: 0.36),
            MemoryBarSegment(id: "active", label: "Apps (activa)", formatted: "5.71 GB", color: .purple, fraction: 0.24),
            MemoryBarSegment(id: "available", label: "Disponible", formatted: "6.42 GB", color: Color.primary.opacity(0.12), fraction: 0.27),
            MemoryBarSegment(id: "cached", label: "Caché (recuperable)", formatted: "6.26 GB", color: .yellow.opacity(0.85), fraction: 0.26, showInBar: false),
            MemoryBarSegment(id: "free", label: "Libre", formatted: "99.2 MB", color: Color.primary.opacity(0.12), fraction: 0.004, showInBar: false)
        ]
    )
    .padding()
    .frame(width: 420)
}
