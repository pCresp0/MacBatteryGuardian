// StatusItemController.swift
// Gestiona el NSStatusItem (ícono de la barra de menú) y el NSPopover flotante.
// Usa AppKit directamente ya que NSStatusItem no tiene soporte nativo en SwiftUI.

import AppKit
import SwiftUI
import Combine

/// Controla el ícono en la barra de menú y el popover flotante.
@MainActor
final class StatusItemController: NSObject {

    // MARK: - Propiedades

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    // nonisolated(unsafe) permite acceder desde deinit (nonisolated en Swift 6)
    // La responsabilidad de acceso exclusivo la garantiza @MainActor en el resto de métodos
    nonisolated(unsafe) private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private let viewModel: MenuBarViewModel
    private let onOpenMainWindow: () -> Void

    // MARK: - Init

    init(monitoringManager: MonitoringManager, onOpenMainWindow: @escaping () -> Void) {
        self.viewModel = monitoringManager.viewModelStore.menuBar
        self.onOpenMainWindow = onOpenMainWindow
        self.statusItem = NSStatusBar.system.statusItem(withLength: 28)
        super.init()

        configureButton()
        configurePopover(monitoringManager: monitoringManager)
        observeViewModel()
    }

    // MARK: - Configuración del botón

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = MenuBarIconRenderer.makeStatusItemImage()
        button.imagePosition = .imageOnly
        button.title = ""
        button.action = #selector(togglePopover)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // MARK: - Configuración del popover

    private func configurePopover(monitoringManager: MonitoringManager) {
        let contentView = PopoverView()
            .environmentObject(monitoringManager.viewModelStore)
            .environmentObject(monitoringManager)

        let hosting = NSHostingController(rootView: contentView)
        // Sin contentSize fijo → el popover toma el tamaño ideal de la vista SwiftUI
        popover.contentViewController = hosting
        popover.behavior = .transient
        popover.animates = true
    }

    // MARK: - Observación del ViewModel

    private var displayedTitle: String = ""
    private var displayedTitleColor: Color = .primary

    private func observeViewModel() {
        Publishers.CombineLatest(viewModel.$title, viewModel.$titleColor)
            .receive(on: RunLoop.main)
            .sink { [weak self] title, color in
                self?.displayedTitle = title
                self?.displayedTitleColor = color
                self?.applyButtonTitle()
            }
            .store(in: &cancellables)

        viewModel.$alertState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.updateButtonAppearance(for: state)
            }
            .store(in: &cancellables)
    }

    private func applyButtonTitle() {
        guard let button = statusItem.button else { return }
        let title = displayedTitle
        let hasMetrics = !title.isEmpty
        statusItem.length = hasMetrics ? NSStatusItem.variableLength : 28
        if hasMetrics {
            button.imagePosition = .imageLeading
            let text = title.hasPrefix(" ") ? title : " \(title)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor(displayedTitleColor)
            ]
            button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        } else {
            button.imagePosition = .imageOnly
            button.attributedTitle = NSAttributedString()
            button.title = ""
        }
    }

    /// Cierra el popover si está abierto (p. ej. al abrir la ventana principal).
    func closePopoverIfOpen() {
        if popover.isShown { closePopover() }
    }

    private func updateButtonAppearance(for state: ConsumptionAlertState) {
        guard let button = statusItem.button else { return }
        switch state {
        case .severe, .critical:
            button.wantsLayer = true
            button.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.15).cgColor
            button.layer?.cornerRadius = 4
        default:
            button.layer?.backgroundColor = .clear
        }
    }

    // MARK: - Acciones

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            closePopover()
        } else {
            openPopover(relativeTo: button)
        }
    }

    private func openPopover(relativeTo button: NSButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        startEventMonitor()
    }

    private func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    // MARK: - Monitor de eventos exteriores (cierre al hacer click fuera)

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    deinit {
        // Accedemos directamente al monitor marcado nonisolated(unsafe)
        // para evitar el problema de @MainActor en deinit (Swift 6)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
