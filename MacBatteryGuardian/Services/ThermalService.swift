// ThermalService.swift
// Servicio que expone el estado térmico del sistema mediante APIs públicas de Apple.
//
// LIMITACIÓN CONOCIDA:
// Apple Silicon no expone temperaturas de sensores individuales a través de APIs públicas.
// Este servicio utiliza exclusivamente `ProcessInfo.thermalState` (4 niveles cualitativos)
// como indicador indirecto del estado térmico del sistema.
// No se accede al SMC ni a APIs privadas.

import Foundation
import Combine

/// Monitoriza el estado térmico del sistema mediante `ProcessInfo.thermalState`.
final class ThermalService: @unchecked Sendable {

    // MARK: - Publisher

    /// Emite el estado térmico cada vez que cambia.
    let thermalStatePublisher: AnyPublisher<SystemThermalState, Never>

    // MARK: - Estado actual

    private(set) var currentThermalState: SystemThermalState = .nominal

    // MARK: - Privado

    private var cancellable: AnyCancellable?
    private let subject = PassthroughSubject<SystemThermalState, Never>()

    // MARK: - Init

    init() {
        thermalStatePublisher = subject.eraseToAnyPublisher()
        startObserving()
    }

    // MARK: - Observación

    private func startObserving() {
        // NSProcessInfo notifica cambios de estado térmico sin polling
        cancellable = NotificationCenter.default
            .publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleThermalStateChange()
            }

        // Leer estado inicial
        handleThermalStateChange()
    }

    private func handleThermalStateChange() {
        let state = mapThermalState(ProcessInfo.processInfo.thermalState)
        currentThermalState = state
        subject.send(state)
    }

    /// Convierte `ProcessInfo.ThermalState` al enum interno.
    private func mapThermalState(_ state: ProcessInfo.ThermalState) -> SystemThermalState {
        switch state {
        case .nominal:  return .nominal
        case .fair:     return .fair
        case .serious:  return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }

    deinit {
        cancellable?.cancel()
    }
}
