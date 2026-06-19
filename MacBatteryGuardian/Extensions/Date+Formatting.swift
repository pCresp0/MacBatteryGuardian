// Date+Formatting.swift
// Extensiones de Date para formateo consistente en toda la aplicación.

import Foundation

extension Date {

    // MARK: - Formateo de tiempo relativo

    /// Retorna una cadena relativa al momento actual: "hace 5 min", "hace 2 h", etc.
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    // MARK: - Formateo de fecha y hora

    /// Formato corto de hora: "14:32"
    var shortTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// Etiqueta legible para estimación de agotamiento: "Hoy a las 18:45", "Mañana a las 06:30"…
    var depletionEstimateFormatted: String {
        let time = shortTimeFormatted
        if Calendar.current.isDateInToday(self) {
            return "Hoy a las \(time)"
        }
        if Calendar.current.isDateInTomorrow(self) {
            return "Mañana a las \(time)"
        }
        return "\(shortDateFormatted) a las \(time)"
    }

    /// Formato de fecha corto: "19 jun"
    var shortDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    /// Formato de fecha y hora completo: "19 jun 2024 14:32"
    var fullDateTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM yyyy HH:mm"
        return formatter.string(from: self)
    }

    // MARK: - Tiempo de actividad

    /// Formatea un intervalo de tiempo como uptime legible.
    static func uptimeFormatted(seconds: TimeInterval) -> String {
        let days  = Int(seconds) / 86_400
        let hours = (Int(seconds) % 86_400) / 3_600
        let mins  = (Int(seconds) % 3_600) / 60

        if days > 0 { return "\(days) d \(hours) h" }
        if hours > 0 { return "\(hours) h \(mins) min" }
        return "\(mins) min"
    }

    /// Formatea minutos de batería: "23 min", "1 h 15 min".
    static func batteryMinutesFormatted(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }

    /// Frase completa de autonomía: "Autonomía: 4 horas y 49 minutos".
    static func batteryAutonomySentence(minutes: Int) -> String {
        guard minutes > 0 else { return "–" }
        if minutes < 60 {
            let unit = minutes == 1 ? "minuto" : "minutos"
            return "Autonomía: \(minutes) \(unit)"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        let hourWord = hours == 1 ? "hora" : "horas"
        if mins == 0 {
            return "Autonomía: \(hours) \(hourWord)"
        }
        let minWord = mins == 1 ? "minuto" : "minutos"
        return "Autonomía: \(hours) \(hourWord) y \(mins) \(minWord)"
    }

    /// Fecha estimada de agotamiento a partir de minutos restantes (IOKit o autonomía calculada).
    static func batteryDepletionEstimate(fromMinutes minutes: Int) -> Date? {
        guard minutes > 0 else { return nil }
        return Date().addingTimeInterval(TimeInterval(minutes * 60))
    }

    /// Frase de agotamiento: "La batería se agotará a las 21:08".
    var batteryDepletionSentence: String {
        let time = shortTimeFormatted
        if Calendar.current.isDateInToday(self) {
            return "La batería se agotará a las \(time)"
        }
        if Calendar.current.isDateInTomorrow(self) {
            return "La batería se agotará mañana a las \(time)"
        }
        return "La batería se agotará el \(shortDateFormatted) a las \(time)"
    }

    /// Etiqueta de tiempo hasta carga completa.
    static func chargeCompleteLabel(minutes: Int) -> String {
        "Carga completa en \(batteryMinutesFormatted(minutes))"
    }

    // MARK: - Comparaciones

    /// Indica si esta fecha es hoy.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Indica si esta fecha es de los últimos N días.
    func isWithinLastDays(_ days: Int) -> Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self >= cutoff
    }
}
