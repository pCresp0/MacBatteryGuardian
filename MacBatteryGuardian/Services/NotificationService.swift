// NotificationService.swift
// Servicio de notificaciones del sistema. Gestiona permisos, deduplicación y categorías.

import Foundation
import UserNotifications
import OSLog

/// Envía notificaciones al usuario con gestión de cooldown para evitar spam.
final class NotificationService: @unchecked Sendable {

    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "NotificationService")
    private let center = UNUserNotificationCenter.current()

    /// Timestamps de la última notificación enviada por categoría.
    private var lastNotificationDates: [String: Date] = [:]

    // MARK: - Permisos

    /// Solicita autorización para enviar notificaciones.
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                logger.info("NotificationService: Permisos de notificación concedidos.")
                registerCategories()
            } else {
                logger.warning("NotificationService: Permisos de notificación denegados.")
            }
        } catch {
            logger.error("NotificationService: Error al solicitar permisos: \(error.localizedDescription)")
        }
    }

    // MARK: - Envío de notificaciones

    /// Envía una notificación respetando el cooldown configurado.
    /// - Parameters:
    ///   - title: Título de la notificación.
    ///   - body: Cuerpo del mensaje.
    ///   - categoryIdentifier: Categoría para el cooldown.
    ///   - cooldownMinutes: Minutos mínimos entre notificaciones del mismo tipo.
    func send(
        title: String,
        body: String,
        categoryIdentifier: String,
        cooldownMinutes: Int = 30
    ) {
        // Comprobar cooldown
        if let lastDate = lastNotificationDates[categoryIdentifier] {
            let elapsed = Date().timeIntervalSince(lastDate) / 60
            guard elapsed >= Double(cooldownMinutes) else {
                logger.debug("NotificationService: Notificación omitida (cooldown activo, \(Int(elapsed)) min < \(cooldownMinutes) min).")
                return
            }
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = categoryIdentifier
        content.sound = categoryIdentifier == Constants.Notifications.categorySevere
            ? .defaultCritical
            : .default

        let request = UNNotificationRequest(
            identifier: "\(categoryIdentifier)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request) { [weak self] error in
            if let error {
                self?.logger.error("NotificationService: Error al enviar notificación: \(error.localizedDescription)")
            } else {
                self?.lastNotificationDates[categoryIdentifier] = Date()
            }
        }
    }

    // MARK: - Registro de categorías

    private func registerCategories() {
        let warningCategory  = UNNotificationCategory(
            identifier: Constants.Notifications.categoryWarning,
            actions: [],
            intentIdentifiers: []
        )
        let criticalCategory = UNNotificationCategory(
            identifier: Constants.Notifications.categoryCritical,
            actions: [],
            intentIdentifiers: []
        )
        let severeCategory   = UNNotificationCategory(
            identifier: Constants.Notifications.categorySevere,
            actions: [],
            intentIdentifiers: []
        )
        let healthCategory   = UNNotificationCategory(
            identifier: Constants.Notifications.categoryHealth,
            actions: [],
            intentIdentifiers: []
        )
        center.setNotificationCategories([warningCategory, criticalCategory, severeCategory, healthCategory])
    }
}
