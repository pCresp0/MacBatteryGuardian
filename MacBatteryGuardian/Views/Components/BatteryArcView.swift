// BatteryArcView.swift
// Indicador circular animado del nivel de batería. Color semántico según porcentaje.

import SwiftUI

struct BatteryArcView: View {

    let percentage: Int
    let isCharging: Bool
    let isPluggedIn: Bool
    /// false en Macs sin batería interna (muestra icono de corriente si está enchufado).
    var hasInternalBattery: Bool = true
    /// Modo bajo consumo activo → acento amarillo estilo macOS.
    var isLowPowerMode: Bool = false

    private var color: Color {
        if isLowPowerMode { return .lowPowerMode }
        if !hasInternalBattery && isPluggedIn { return .green }
        return .batteryColor(percentage: percentage)
    }
    private var progress: Double {
        if !hasInternalBattery && isPluggedIn { return 1.0 }
        return Double(percentage) / 100.0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            if !hasInternalBattery && isPluggedIn {
                Image(systemName: "powerplug.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            } else if isCharging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            } else if isPluggedIn {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            } else {
                Text("\(percentage)%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        BatteryArcView(percentage: 85, isCharging: false, isPluggedIn: false)
            .frame(width: 80, height: 80)
        BatteryArcView(percentage: 42, isCharging: true, isPluggedIn: true)
            .frame(width: 80, height: 80)
        BatteryArcView(percentage: 12, isCharging: false, isPluggedIn: false)
            .frame(width: 80, height: 80)
    }
    .padding()
}
