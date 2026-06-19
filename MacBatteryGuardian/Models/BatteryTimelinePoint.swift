// BatteryTimelinePoint.swift
// Punto de la cronología de batería con estado de alimentación (12 h).

import Foundation

struct BatteryTimelinePoint: Identifiable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let level: Double
    let isPluggedIn: Bool
    let isCharging: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        level: Double,
        isPluggedIn: Bool,
        isCharging: Bool
    ) {
        self.id = id
        self.date = date
        self.level = level
        self.isPluggedIn = isPluggedIn
        self.isCharging = isCharging
    }

    static func from(record: HistoricalRecord) -> BatteryTimelinePoint {
        BatteryTimelinePoint(
            date: record.timestamp,
            level: Double(record.batteryPercentage),
            isPluggedIn: record.isPluggedIn,
            isCharging: record.isCharging
        )
    }

    static func from(snapshot: BatterySnapshot) -> BatteryTimelinePoint {
        BatteryTimelinePoint(
            date: snapshot.recordedAt,
            level: Double(snapshot.percentage),
            isPluggedIn: snapshot.isPluggedIn,
            isCharging: snapshot.isCharging
        )
    }
}

enum BatteryTimelineChart {
    static let windowHours: Double = 12
    static var windowSeconds: TimeInterval { windowHours * 3600 }

    static func windowStart(relativeTo now: Date = Date()) -> Date {
        now.addingTimeInterval(-windowSeconds)
    }
}

enum BatteryTimelineBuilder {

    /// Combina historial persistido y muestras en vivo, recortado a la ventana de 12 h.
    static func merge(
        historical: [HistoricalRecord],
        live: [BatteryTimelinePoint],
        relativeTo now: Date = Date()
    ) -> [BatteryTimelinePoint] {
        let cutoff = BatteryTimelineChart.windowStart(relativeTo: now)
        var bySecond: [Int: BatteryTimelinePoint] = [:]

        for record in historical where record.timestamp >= cutoff {
            let point = BatteryTimelinePoint.from(record: record)
            bySecond[Int(point.date.timeIntervalSince1970)] = point
        }
        for point in live where point.date >= cutoff {
            bySecond[Int(point.date.timeIntervalSince1970)] = point
        }

        return bySecond.values.sorted { $0.date < $1.date }
    }

    /// Intervalos conectado a corriente (fondo verde en la gráfica).
    static func pluggedInIntervals(
        from points: [BatteryTimelinePoint],
        relativeTo now: Date = Date()
    ) -> [DateInterval] {
        stateIntervals(from: points, relativeTo: now) { $0.isPluggedIn }
    }

    /// Intervalos con carga activa (rayo en la franja inferior).
    static func chargingIntervals(
        from points: [BatteryTimelinePoint],
        relativeTo now: Date = Date()
    ) -> [DateInterval] {
        stateIntervals(from: points, relativeTo: now) { $0.isCharging }
    }

    static func footerDescription(for points: [BatteryTimelinePoint]) -> String {
        guard !points.isEmpty else {
            return "Últimas 12 horas · sin datos aún"
        }
        return "Últimas 12 horas · \(points.count) muestras"
    }

    // MARK: - Privado

    private static func stateIntervals(
        from points: [BatteryTimelinePoint],
        relativeTo now: Date,
        isActive: (BatteryTimelinePoint) -> Bool
    ) -> [DateInterval] {
        let sorted = points.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }

        var intervals: [DateInterval] = []

        for index in 0..<(sorted.count - 1) {
            let current = sorted[index]
            guard isActive(current) else { continue }
            intervals.append(DateInterval(start: current.date, end: sorted[index + 1].date))
        }

        if let last = sorted.last, isActive(last) {
            intervals.append(DateInterval(start: last.date, end: now))
        }

        return coalesce(intervals)
    }

    private static func coalesce(_ intervals: [DateInterval]) -> [DateInterval] {
        guard var merged = intervals.sorted(by: { $0.start < $1.start }).first.map({ [$0] }) else {
            return []
        }
        for interval in intervals.dropFirst() {
            if let last = merged.last, interval.start.timeIntervalSince(last.end) <= 120 {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }
        return merged
    }
}
