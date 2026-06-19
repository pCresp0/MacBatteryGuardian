// AlertManager.swift
// Evalúa el estado de alerta y toma las acciones correspondientes:
// notificaciones, activación de Low Power Mode y registro de culpables.

import Foundation
import OSLog

/// Ejecuta las acciones correspondientes a cada estado de alerta del motor de decisiones.
actor AlertManager {

    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "AlertManager")

    // MARK: - Estado interno

    private var lastAlertState: ConsumptionAlertState = .stable
    private var criticalStateEnteredAt: Date?
    private var lowPowerModeActivatedAutomatically = false

    // MARK: - Evaluación

    /// Evalúa el estado actual y ejecuta las acciones necesarias.
    func evaluate(
        metrics: EnergyMetrics,
        battery: BatterySnapshot,
        processes: [ProcessSnapshot],
        notificationService: NotificationService,
        powerService: PowerManagementService
    ) async {
        let state = metrics.alertState
        let settings = SettingsRepository.shared

        // Detectar cambio de estado hacia arriba
        if state.rawValue > lastAlertState.rawValue {
            await handleStateEscalation(
                newState: state,
                metrics: metrics,
                battery: battery,
                processes: processes,
                notificationService: notificationService,
                powerService: powerService,
                settings: settings
            )
        }

        // Detectar vuelta a estado normal (cargador conectado)
        if battery.isPluggedIn && lastAlertState != .stable {
            await handleChargerConnected(powerService: powerService, settings: settings)
        }

        // Verificar si corresponde activar LPM por tiempo en estado crítico
        if state == .critical || state == .severe {
            if criticalStateEnteredAt == nil {
                criticalStateEnteredAt = Date()
            }
            await checkLowPowerModeActivation(
                powerService: powerService,
                settings: settings,
                notificationService: notificationService
            )
        } else {
            criticalStateEnteredAt = nil
        }

        lastAlertState = state
    }

    // MARK: - Escalada de estado

    private func handleStateEscalation(
        newState: ConsumptionAlertState,
        metrics: EnergyMetrics,
        battery: BatterySnapshot,
        processes: [ProcessSnapshot],
        notificationService: NotificationService,
        powerService: PowerManagementService,
        settings: SettingsRepository
    ) async {
        logger.info("AlertManager: Escalada a estado \(newState.rawValue).")

        switch newState {
        case .warning:
            notificationService.send(
                title: "Consumo energético elevado",
                body: "El consumo energético es superior al habitual (\(metrics.currentRatePerHour.map { String(format: "%.1f", $0) } ?? "–") %/h).",
                categoryIdentifier: Constants.Notifications.categoryWarning,
                cooldownMinutes: settings.notificationCooldownMinutes
            )

        case .critical:
            notificationService.send(
                title: "Consumo energético crítico",
                body: "Consumo muy elevado detectado. Si se mantiene, se activará el Modo Bajo Consumo.",
                categoryIdentifier: Constants.Notifications.categoryCritical,
                cooldownMinutes: settings.notificationCooldownMinutes
            )

        case .severe:
            let culprit = processes.first.map { "Posible causa: \($0.name)." } ?? ""
            notificationService.send(
                title: "Se ha detectado un consumo muy elevado",
                body: "El consumo supera el 30 %/h. \(culprit)",
                categoryIdentifier: Constants.Notifications.categorySevere,
                cooldownMinutes: settings.notificationCooldownMinutes
            )
            logger.warning("AlertManager: Estado SEVERE. Culpables: \(processes.prefix(3).map(\.name).joined(separator: ", ")).")

        case .stable, .elevated:
            break
        }
    }

    // MARK: - Activación automática de Low Power Mode

    private func checkLowPowerModeActivation(
        powerService: PowerManagementService,
        settings: SettingsRepository,
        notificationService: NotificationService
    ) async {
        guard settings.automaticLowPowerModeEnabled,
              !lowPowerModeActivatedAutomatically,
              let enteredAt = criticalStateEnteredAt else { return }

        let minutesInCritical = Date().timeIntervalSince(enteredAt) / 60
        guard minutesInCritical >= Double(settings.lowPowerModeActivationDelayMinutes) else { return }

        logger.info("AlertManager: Activando Low Power Mode automáticamente (\(Int(minutesInCritical)) min en estado crítico).")
        let success = await powerService.setLowPowerMode(enabled: true)
        if success {
            lowPowerModeActivatedAutomatically = true
            notificationService.send(
                title: "Modo Bajo Consumo activado",
                body: "MacBatteryGuardian ha activado el Modo Bajo Consumo para proteger la autonomía.",
                categoryIdentifier: Constants.Notifications.categoryCritical,
                cooldownMinutes: 60
            )
        }
    }

    // MARK: - Cargador conectado

    private func handleChargerConnected(
        powerService: PowerManagementService,
        settings: SettingsRepository
    ) async {
        criticalStateEnteredAt = nil

        guard settings.deactivateLowPowerOnCharge,
              lowPowerModeActivatedAutomatically else { return }

        logger.info("AlertManager: Cargador conectado. Desactivando Low Power Mode automático.")
        let success = await powerService.setLowPowerMode(enabled: false)
        if success {
            lowPowerModeActivatedAutomatically = false
        }
    }
}
