// ProcessRowView.swift
// Fila para mostrar la información de un proceso. Tiene dos modos: compacto (popover)
// y expandido (ventana principal).

import SwiftUI

struct ProcessRowView: View {

    let process: ProcessSnapshot
    let compact: Bool

    var body: some View {
        if compact {
            compactRow
        } else {
            expandedRow
        }
    }

    // MARK: - Compacto (popover)

    private var compactRow: some View {
        HStack(spacing: 8) {
            processIcon
                .frame(width: 20, height: 20)

            Text(process.name)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            Text(process.cpuPercent.cpuUsageFormatted)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(cpuColor)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    // MARK: - Expandido (ventana principal)

    private var expandedRow: some View {
        HStack(spacing: 10) {
            processIcon
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(.subheadline)
                    .lineLimit(1)

                if !process.path.isEmpty {
                    Text(process.path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // CPU
            VStack(alignment: .trailing, spacing: 2) {
                Text(process.cpuPercent.cpuUsageFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(cpuColor)
                    .monospacedDigit()
                Text("CPU")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 55)

            // Memoria
            VStack(alignment: .trailing, spacing: 2) {
                Text(process.memoryMB.bytesFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                Text("RAM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 65)

            // Índice de impacto
            impactBadge
        }
        .padding(.vertical, 4)
    }

    // MARK: - Componentes

    private var processIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(iconBackground)
            Image(systemName: processIconName)
                .font(.system(size: compact ? 10 : 13))
                .foregroundStyle(.white)
        }
    }

    private var impactBadge: some View {
        Text(String(format: "%.0f", process.energyImpactIndex))
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(impactColor)
            )
            .frame(width: 42)
    }

    // MARK: - Helpers

    private var cpuColor: Color {
        switch process.cpuPercent {
        case let c where c >= 30: return .red
        case let c where c >= 15: return .orange
        case let c where c >= 5:  return .yellow
        default: return .secondary
        }
    }

    private var impactColor: Color {
        switch process.energyImpactIndex {
        case let i where i >= 60: return .red
        case let i where i >= 35: return .orange
        case let i where i >= 15: return .yellow
        default: return .green
        }
    }

    private var iconBackground: Color {
        process.isSystemProcess ? .gray : .blue
    }

    private var processIconName: String {
        switch process.name.lowercased() {
        case let n where n.contains("chrome"):  return "globe"
        case let n where n.contains("safari"):  return "safari"
        case let n where n.contains("firefox"): return "globe"
        case let n where n.contains("docker"):  return "shippingbox"
        case let n where n.contains("node"):    return "terminal"
        case let n where n.contains("cursor"):  return "cursorarrow"
        case let n where n.contains("code"):    return "curlybraces"
        case let n where n.contains("xcode"):   return "hammer"
        default: return "app"
        }
    }
}
