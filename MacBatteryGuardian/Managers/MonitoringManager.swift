// MonitoringManager.swift
// Coordinador principal del ciclo de monitorización. Orquesta todos los servicios,
// gestiona el estado de sleep/wake y publica snapshots a los ViewModels.

import Foundation
import Combine
import OSLog

/// Coordina el ciclo de monitorización y actúa como fuente de verdad del estado del sistema.
@MainActor
final class MonitoringManager: ObservableObject {

    // MARK: - Singleton

    static let shared = MonitoringManager()

    // MARK: - Estado publicado

    @Published private(set) var latestBattery: BatterySnapshot?
    @Published private(set) var latestSystem: SystemSnapshot?
    @Published private(set) var latestProcesses: [ProcessSnapshot] = []
    @Published private(set) var latestMetrics: EnergyMetrics?
    @Published private(set) var latestHealthScore: HealthScore?
    @Published private(set) var powerModeState: PowerModeState = .normal
    @Published private(set) var isMonitoring: Bool = false
    @Published private(set) var lastUpdateDate: Date?

    // MARK: - Store para ViewModels

    /// Contenedor para inyectar en el entorno de SwiftUI.
    let viewModelStore = ViewModelStore()

    // MARK: - Servicios

    private let batteryService        = BatteryService()
    private let systemMetricsService  = SystemMetricsService()
    private let processMonitorService = ProcessMonitorService()
    private let thermalService        = ThermalService()
    private let powerService          = PowerManagementService()
    private let notificationService   = NotificationService()
    private let persistenceService    = PersistenceService()

    // MARK: - Managers

    private let decisionEngine    = DecisionEngine()
    private let alertManager      = AlertManager()
    private let healthManager     = HealthScoreManager()

    // MARK: - Estado interno

    private var monitoringTask: Task<Void, Never>?
    private var isSuspended = false
    /// Escaneo completo de procesos solo cada N ciclos (ahorro de batería).
    private var cycleCount = 0
    private var cachedProcesses: [ProcessSnapshot] = []
    private let processScanEveryNCycles = 3
    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "MonitoringManager")

    // MARK: - Init

    private init() {
        setupThermalObservation()
        setupPowerModeObservation()
    }

    // MARK: - Ciclo de vida

    /// Inicia la monitorización. Seguro para llamar múltiples veces.
    func start() async {
        guard monitoringTask == nil else { return }
        isMonitoring = true
        logger.info("MonitoringManager: Iniciando monitorización (intervalo: \(SettingsRepository.shared.monitoringIntervalSeconds) s).")

        // Primera lectura: establece el baseline de CPU (devuelve 0% — sin delta previo)
        await runMonitoringCycle()

        // Segunda lectura 2 segundos después: ya hay delta → CPU muestra valor real
        try? await Task.sleep(for: .seconds(2))
        await runMonitoringCycle()

        monitoringTask = Task { [weak self] in
            await self?.monitoringLoop()
        }
    }

    /// Detiene la monitorización.
    func stop() async {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        await persistenceService.flushBuffer()
        logger.info("MonitoringManager: Monitorización detenida.")
    }

    /// Suspende el ciclo de monitorización (durante sleep del sistema).
    func suspend() async {
        isSuspended = true
        logger.debug("MonitoringManager: Ciclo suspendido.")
    }

    /// Reanuda el ciclo (tras wake del sistema) y ejecuta un ciclo inmediato.
    func resume() async {
        isSuspended = false
        logger.debug("MonitoringManager: Ciclo reanudado.")
        await runMonitoringCycle()
    }

    // MARK: - Bucle principal

    private func monitoringLoop() async {
        let settings = SettingsRepository.shared
        while !Task.isCancelled {
            let intervalSeconds = isSuspended ? 60 : settings.monitoringIntervalSeconds
            do {
                try await Task.sleep(for: .seconds(intervalSeconds))
            } catch {
                // Task cancelada
                break
            }
            guard !Task.isCancelled, !isSuspended else { continue }
            await runMonitoringCycle()
        }
    }

    /// Fuerza una lectura inmediata (p. ej. botón Actualizar del popover).
    func refreshNow() async {
        await runMonitoringCycle(forceProcessScan: true)
    }

    // MARK: - Ciclo de monitorización

    private func runMonitoringCycle(forceProcessScan: Bool = false) async {
        logger.debug("MonitoringManager: Iniciando ciclo de monitorización.")

        cycleCount += 1
        let shouldScanProcesses = forceProcessScan || cycleCount % processScanEveryNCycles == 0

        async let batteryRead = batteryService.readSnapshot()
        async let systemRead  = systemMetricsService.readSnapshot()

        let battery = await batteryRead
        let system  = await systemRead
        let processes: [ProcessSnapshot]
        if shouldScanProcesses {
            processes = await processMonitorService.readTopProcesses(topCount: 10)
            cachedProcesses = processes
        } else {
            processes = cachedProcesses
        }

        let metrics = await decisionEngine.processReading(
            batteryPercent: battery?.percentage,
            isPluggedIn: battery?.isPluggedIn ?? true
        )

        let health = healthManager.calculateScore(
            battery: battery,
            system: system,
            metrics: metrics,
            processes: processes
        )

        let newPowerState = await powerService.currentPowerModeState()

        // Actualizar en hilo principal
        await MainActor.run {
            self.latestBattery    = battery
            self.latestSystem     = system
            self.latestProcesses  = processes
            self.latestMetrics    = metrics
            self.latestHealthScore = health
            self.powerModeState   = newPowerState
            self.lastUpdateDate   = Date()
            self.viewModelStore.update(
                battery: battery,
                system: system,
                processes: processes,
                metrics: metrics,
                health: health,
                powerMode: newPowerState
            )
        }

        // Evaluar alertas y acciones automáticas (metrics no es Optional)
        if let battery {
            await alertManager.evaluate(
                metrics: metrics,
                battery: battery,
                processes: processes,
                notificationService: notificationService,
                powerService: powerService
            )

            // Persistir registro
            let record = HistoricalRecord.from(
                battery: battery,
                system: system,
                metrics: metrics,
                topProcesses: processes
            )
            await persistenceService.append(record)
        }

        logger.debug("MonitoringManager: Ciclo completado.")
    }

    // MARK: - Observaciones externas

    private func setupThermalObservation() {
        // ThermalService ya observa cambios vía NotificationCenter
    }

    private func setupPowerModeObservation() {
        // Observar cambios del Low Power Mode del sistema (sin polling)
        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let newState = await self.powerService.currentPowerModeState()
                self.powerModeState = newState
                self.viewModelStore.syncPowerMode(newState)
            }
        }
    }

    // MARK: - Activación manual de Low Power Mode

    func setLowPowerMode(enabled: Bool) async {
        let success = await powerService.setLowPowerMode(enabled: enabled)
        guard success else { return }

        // Breve pausa para que pmset / ProcessInfo reflejen el cambio
        try? await Task.sleep(for: .milliseconds(300))
        let verified = await powerService.currentPowerModeState()
        let state = PowerModeState(
            mode: verified.mode,
            source: .manual,
            activatedAt: verified.mode == .lowPower ? Date() : nil
        )
        await MainActor.run {
            self.powerModeState = state
            self.viewModelStore.syncPowerMode(state)
        }
    }
}
