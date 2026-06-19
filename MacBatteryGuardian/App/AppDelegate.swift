// AppDelegate.swift
// Gestiona el ciclo de vida de la app: inicialización, sleep/wake, barra de menú y ventana principal.

import AppKit
import SwiftUI
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Dependencias

    private let monitoringManager = MonitoringManager.shared
    private let settingsRepository = SettingsRepository.shared
    private let loginItemManager = LoginItemManager()
    private let notificationService = NotificationService()

    // MARK: - UI

    private var statusItemController: StatusItemController?
    private var mainWindow: NSWindow?

    // MARK: - Logging

    private let logger = Logger(subsystem: "com.macbatteryguardian.app", category: "AppDelegate")

    // MARK: - NSApplicationDelegateAdaptor

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ocultar el ícono del Dock (es una app de barra de menú)
        NSApp.setActivationPolicy(.accessory)

        // Solicitar permisos de notificación
        Task {
            await notificationService.requestAuthorization()
        }

        // Registrar como Login Item si está configurado
        if settingsRepository.launchAtLogin {
            loginItemManager.enable()
        }

        // Iniciar monitorización en segundo plano
        Task {
            await monitoringManager.start()
        }

        // Crear el ícono en la barra de menú
        statusItemController = StatusItemController(
            monitoringManager: monitoringManager,
            onOpenMainWindow: { [weak self] in
                self?.openMainWindow()
            }
        )

        // Observar notificación de "abrir ventana" enviada desde el popover
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenMainWindow),
            name: .openMainWindow,
            object: nil
        )

        // Observar sleep y wake del sistema
        registerSystemNotifications()
        registerMainWindowResizeObserver()

        logger.info("MacBatteryGuardian iniciado correctamente.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task {
            await monitoringManager.stop()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // La app no termina al cerrar la ventana; sigue en la barra de menú.
        false
    }

    // MARK: - Ventana principal

    // MARK: - Ventana principal

    enum MainWindow {
        static let defaultSize = NSSize(width: MainWindowSizer.windowWidth, height: 720)
        static let minSize = NSSize(width: 800, height: MainWindowSizer.minWindowHeight)
    }

    func openMainWindow(tab: AppTab = .general) {
        statusItemController?.closePopoverIfOpen()

        if let existing = mainWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(
                name: .selectMainWindowTab,
                object: nil,
                userInfo: [MainWindowNavigation.tabUserInfoKey: tab.rawValue]
            )
            return
        }

        let contentView = MainWindowView(initialTab: tab)
            .environmentObject(monitoringManager.viewModelStore)
            .environmentObject(monitoringManager)
            .environmentObject(monitoringManager.viewModelStore.settingsVM)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: MainWindow.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.minSize = MainWindow.minSize
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        MainWindowChrome.configure(window)
        mainWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func handleOpenMainWindow(_ notification: Notification) {
        let tab = (notification.userInfo?[MainWindowNavigation.tabUserInfoKey] as? String)
            .flatMap(AppTab.init(rawValue:))
        openMainWindow(tab: tab ?? .general)
    }

    @objc private func handleMainWindowResize(_ notification: Notification) {
        guard
            let bodyHeight = notification.userInfo?[MainWindowResizePayload.bodyHeightKey] as? CGFloat
        else { return }
        let animated = notification.userInfo?[MainWindowResizePayload.animatedKey] as? Bool ?? false
        resizeMainWindow(bodyHeight: bodyHeight, animated: animated)
    }

    private func registerMainWindowResizeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMainWindowResize(_:)),
            name: .mainWindowResizeToContent,
            object: nil
        )
    }

    private func resizeMainWindow(bodyHeight: CGFloat, animated: Bool) {
        guard let window = mainWindow, window.isVisible else { return }

        let titleBar = window.frame.height - window.contentLayoutRect.height
        let contentTotal = bodyHeight + MainWindowSizer.tabBarHeight
        let screenMax = (window.screen?.visibleFrame.height ?? 900) * 0.92
        let targetContent = min(
            max(contentTotal, MainWindowSizer.minWindowHeight - titleBar),
            screenMax - titleBar
        )
        let targetFrameHeight = targetContent + titleBar

        var frame = window.frame
        frame.origin.y += frame.size.height - targetFrameHeight
        frame.size.height = targetFrameHeight
        frame.size.width = MainWindowSizer.windowWidth

        window.minSize = NSSize(width: 800, height: MainWindowSizer.minWindowHeight)
        window.setFrame(frame, display: true, animate: animated)
    }

    // MARK: - Notificaciones del sistema

    private func registerSystemNotifications() {
        let workspaceNC = NSWorkspace.shared.notificationCenter

        workspaceNC.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspaceNC.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func systemWillSleep() {
        logger.debug("Sistema entrando en reposo. Pausando monitorización.")
        Task {
            await monitoringManager.suspend()
        }
    }

    @objc private func systemDidWake() {
        logger.debug("Sistema reactivado. Reanudando monitorización.")
        Task {
            await monitoringManager.resume()
        }
    }
}
