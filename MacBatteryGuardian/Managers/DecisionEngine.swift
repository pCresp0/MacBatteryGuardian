// DecisionEngine.swift
// Motor de decisiones inteligente. Trabaja con ventanas deslizantes para detectar
// tendencias sostenidas, evitando reaccionar a picos puntuales.

import Foundation
import OSLog

/// Motor de decisiones que analiza el consumo energético a lo largo del tiempo.
actor DecisionEngine {

    // MARK: - Estado interno

    /// Historial de lecturas de porcentaje de batería con sus timestamps.
    private struct BatteryReading {
        let percentage: Int
        let recordedAt: Date
    }

    private var readings: [BatteryReading] = []
    private var currentState: ConsumptionAlertState = .stable
    private var stateConfirmationCount: Int = 0
    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "DecisionEngine")

    // MARK: - Procesamiento

    /// Procesa una nueva lectura y devuelve las métricas actualizadas.
    /// - Parameters:
    ///   - batteryPercent: Porcentaje actual de batería. Nil si el Mac no tiene batería.
    ///   - isPluggedIn: Si el cargador está conectado.
    /// - Returns: `EnergyMetrics` calculadas sobre la ventana deslizante.
    func processReading(
        batteryPercent: Int?,
        isPluggedIn: Bool
    ) async -> EnergyMetrics {
        let now = Date()

        if let percent = batteryPercent, !isPluggedIn {
            readings.append(BatteryReading(percentage: percent, recordedAt: now))
        }

        // Mantener solo lecturas dentro de la ventana máxima (3 horas)
        let threeHoursAgo = now.addingTimeInterval(-3 * 3600)
        readings = readings.filter { $0.recordedAt >= threeHoursAgo }

        // Calcular tasas por ventana temporal
        let rate15min = calculateRate(within: 15 * 60)
        let rate30min = calculateRate(within: 30 * 60)
        let rate1h    = calculateRate(within: 3600)
        let rate3h    = calculateRate(within: 3 * 3600)

        // Calcular tendencia
        let trend: ConsumptionTrend
        if let current = rate15min, let base = rate1h {
            trend = ConsumptionTrend.calculate(currentRate: current, baseRate: base)
        } else {
            trend = .unknown
        }

        // Autonomía estimada (consumo medio)
        let autonomy = estimateAutonomy(
            averageRate: averageRate(from: rate15min, rate30min, rate1h, rate3h),
            batteryPercent: batteryPercent
        )

        // Nuevo estado de alerta
        let newAlertState = determineAlertState(currentRate: rate15min ?? rate30min ?? rate1h)

        return EnergyMetrics(
            ratePerHour15min: rate15min,
            ratePerHour30min: rate30min,
            ratePerHour1h: rate1h,
            ratePerHour3h: rate3h,
            trend: trend,
            estimatedAutonomyMinutes: isPluggedIn ? nil : autonomy,
            dailyAverageRatePerHour: nil,
            weeklyAverageRatePerHour: nil,
            alertState: newAlertState
        )
    }

    // MARK: - Cálculo de tasa

    /// Calcula la tasa de consumo en %/hora para los últimos `seconds` segundos.
    private func calculateRate(within seconds: TimeInterval) -> Double? {
        let cutoff = Date().addingTimeInterval(-seconds)
        let window = readings.filter { $0.recordedAt >= cutoff }
        guard window.count >= 2 else { return nil }

        guard let first = window.first, let last = window.last else { return nil }
        let elapsed = last.recordedAt.timeIntervalSince(first.recordedAt)
        guard elapsed >= Constants.Monitoring.minimumSampleDurationSeconds else { return nil }

        let percentDrop = Double(first.percentage - last.percentage)
        guard percentDrop > 0 else { return nil }

        let rawRate = (percentDrop / elapsed) * 3600
        return sanitizeRate(rawRate)
    }

    /// Acota la tasa a un rango físicamente posible (0–100 %/h).
    private func sanitizeRate(_ rate: Double) -> Double? {
        guard rate > 0 else { return nil }
        let capped = min(rate, Constants.Thresholds.maximumRatePerHour)
        return capped
    }

    // MARK: - Estado de alerta con protección anti-flapping

    /// Determina el estado de alerta usando un contador de confirmación.
    /// Para SUBIR de estado se requieren 2 lecturas consecutivas.
    /// Para BAJAR de estado se requieren 3 lecturas consecutivas.
    private func determineAlertState(currentRate: Double?) -> ConsumptionAlertState {
        guard let rate = currentRate else { return currentState }

        let candidateState = rawStateFor(rate: rate)

        if candidateState.rawValue > currentState.rawValue {
            // Intento de subir de nivel
            stateConfirmationCount += 1
            if stateConfirmationCount >= Constants.Thresholds.confirmationReadingsUp {
                currentState = candidateState
                stateConfirmationCount = 0
                logger.info("DecisionEngine: Estado → \(candidateState.rawValue) (tasa: \(String(format: "%.1f", rate)) %/h).")
            }
        } else if candidateState.rawValue < currentState.rawValue {
            // Intento de bajar de nivel
            stateConfirmationCount -= 1
            if stateConfirmationCount <= -Constants.Thresholds.confirmationReadingsDown {
                currentState = candidateState
                stateConfirmationCount = 0
                logger.info("DecisionEngine: Estado ↓ \(candidateState.rawValue) (tasa: \(String(format: "%.1f", rate)) %/h).")
            }
        } else {
            stateConfirmationCount = 0
        }

        return currentState
    }

    private func rawStateFor(rate: Double) -> ConsumptionAlertState {
        switch rate {
        case let r where r >= Constants.Thresholds.severe:    return .severe
        case let r where r >= Constants.Thresholds.critical:  return .critical
        case let r where r >= Constants.Thresholds.warning:   return .warning
        case let r where r >= Constants.Thresholds.elevated:  return .elevated
        default:                                               return .stable
        }
    }

    // MARK: - Autonomía estimada

    private func estimateAutonomy(averageRate: Double?, batteryPercent: Int?) -> Int? {
        guard let rate = averageRate, rate > 0, let percent = batteryPercent else { return nil }
        let hoursRemaining = Double(percent) / rate
        return Int(hoursRemaining * 60)
    }

    private func averageRate(
        from rate15min: Double?,
        _ rate30min: Double?,
        _ rate1h: Double?,
        _ rate3h: Double?
    ) -> Double? {
        let rates = [rate15min, rate30min, rate1h, rate3h].compactMap { $0 }
        guard !rates.isEmpty else { return nil }
        return rates.reduce(0, +) / Double(rates.count)
    }

    // MARK: - Reset

    /// Limpia el historial de lecturas (útil al conectar el cargador).
    func reset() {
        readings.removeAll()
        currentState = .stable
        stateConfirmationCount = 0
    }
}
