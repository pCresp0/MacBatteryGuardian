// BatteryHorizontalBarView.swift
// Indicador horizontal de batería — distinto del arco circular de salud.

import SwiftUI

struct BatteryHorizontalBarView: View {

    let percentage: Int
    let isCharging: Bool
    let isPluggedIn: Bool

    private var tint: Color { Color.batteryColor(percentage: percentage) }

    var body: some View {
        HStack(spacing: 3) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(height: 22)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(tint)
                    .frame(width: max(8, 132 * CGFloat(percentage) / 100), height: 18)
                    .padding(.leading, 2)

                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 136, height: 22)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(tint.opacity(0.45))
                .frame(width: 4, height: 11)
        }
    }
}
