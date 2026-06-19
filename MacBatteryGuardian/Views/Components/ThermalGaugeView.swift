// ThermalGaugeView.swift
// Barra de temperatura con lectura honesta (batería + estimación del sistema).

import SwiftUI

struct ThermalGaugeView: View {

    let thermalState: SystemThermalState
    let reading: ThermalReading

    private let minTemp: Double = 20
    private let maxTemp: Double = 60
    private let barHeight: CGFloat = 8

    private let gradientColors: [Color] = [
        Color(red: 0.2, green: 0.5, blue: 1.0),
        Color(red: 0.2, green: 0.85, blue: 0.45),
        Color(red: 1.0, green: 0.75, blue: 0.0),
        Color(red: 1.0, green: 0.4, blue: 0.0),
        Color(red: 0.9, green: 0.1, blue: 0.1)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            temperatureHeader
            gaugeBar
            rangeLegend
            if let disclaimer = reading.disclaimer {
                Text(disclaimer)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Cabecera

    @ViewBuilder
    private var temperatureHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "thermometer.medium")
                .font(.caption)
                .foregroundStyle(markerColor)

            if let temp = reading.celsius {
                HStack(spacing: 4) {
                    Text(String(format: "%.0f°C", temp))
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(markerColor)
                    if reading.isEstimated {
                        Text("≈")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("· \(reading.sourceLabel)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text(thermalState.localizedDescription)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(markerColor)
                Text("· sin sensor en °C")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(reading.badgeLabel)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(markerColor.opacity(0.85), in: Capsule())
        }
    }

    // MARK: - Barra

    @ViewBuilder
    private var gaugeBar: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let centerY = geo.size.height / 2
            let markerX = markerPosition(width: w)

            ZStack {
                Capsule()
                    .fill(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: w, height: barHeight)
                    .position(x: w / 2, y: centerY)

                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: markerColor.opacity(0.5), radius: 2)
                    Circle()
                        .fill(markerColor)
                        .frame(width: 8, height: 8)
                }
                .position(x: markerX, y: centerY)
                .animation(.spring(duration: 0.5), value: markerX)
            }
        }
        .frame(height: 20)
    }

    @ViewBuilder
    private var rangeLegend: some View {
        HStack(spacing: 0) {
            Text("< 35°C").frame(maxWidth: .infinity, alignment: .leading)
            Text("Templado").frame(maxWidth: .infinity, alignment: .center)
            Text("> 45°C").frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 9))
        .foregroundStyle(.secondary)
    }

    // MARK: - Cálculos

    private func markerPosition(width: CGFloat) -> CGFloat {
        let fraction: CGFloat
        if let temp = reading.celsius {
            fraction = CGFloat(((temp - minTemp) / (maxTemp - minTemp)).clamped(to: 0...1))
        } else {
            fraction = CGFloat(thermalStateFraction)
        }
        return max(7, min(width - 7, fraction * width))
    }

    private var thermalStateFraction: Double {
        switch thermalState {
        case .nominal:  return 0.20
        case .fair:     return 0.55
        case .serious:  return 0.78
        case .critical: return 0.95
        }
    }

    private var markerColor: Color {
        let f: Double
        if let temp = reading.celsius {
            f = ((temp - minTemp) / (maxTemp - minTemp)).clamped(to: 0...1)
        } else {
            f = thermalStateFraction
        }
        if f < 0.35 { return Color(red: 0.2, green: 0.85, blue: 0.45) }
        if f < 0.55 { return Color(red: 1.0, green: 0.75, blue: 0.0) }
        if f < 0.75 { return Color(red: 1.0, green: 0.4, blue: 0.0) }
        return Color(red: 0.9, green: 0.1, blue: 0.1)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
