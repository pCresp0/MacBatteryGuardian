// TimelineSample.swift
// Punto de una serie temporal en vivo (fecha + valor).

import Foundation

struct TimelineSample: Identifiable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let value: Double

    init(date: Date = Date(), value: Double) {
        self.id = UUID()
        self.date = date
        self.value = value
    }
}

enum TimelineHistory {
    /// Añade una muestra y recorta al máximo de puntos (cronología deslizante).
    static func append(_ value: Double, to history: inout [TimelineSample], maxPoints: Int) {
        history.append(TimelineSample(value: value))
        if history.count > maxPoints {
            history.removeFirst(history.count - maxPoints)
        }
    }

    static func spanDescription(for samples: [TimelineSample]) -> String {
        guard samples.count >= 2,
              let first = samples.first?.date,
              let last = samples.last?.date else {
            return samples.isEmpty
                ? "Sin datos — se irá rellenando con cada lectura"
                : "Recopilando datos… (1 muestra)"
        }
        let minutes = max(1, Int(last.timeIntervalSince(first) / 60))
        let duration = formatDuration(minutes)
        return "Últimos \(duration) · \(samples.count) muestras"
    }

    private static func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }
}
