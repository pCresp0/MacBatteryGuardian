// DetailStatBlock.swift
// Bloque de estadística grande para pestañas de detalle.

import SwiftUI

struct DetailStatBlock: View {
    let label: String
    let value: String
    var color: Color = .primary
    var footnote: String? = nil
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            Text(label)
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(compact ? .subheadline : .title2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            if let footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DetailMetricPill: View {
    let title: String
    let value: String
    var tint: Color = .primary
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 3 : 6) {
            Text(value)
                .font(compact ? .subheadline : .title3)
                .fontWeight(.bold)
                .foregroundStyle(tint)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 8 : 12)
        .liquidGlassInset(cornerRadius: LiquidGlassTokens.insetRadius)
    }
}
