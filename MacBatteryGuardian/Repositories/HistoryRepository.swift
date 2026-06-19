// HistoryRepository.swift
// Capa de acceso al historial de registros. Delega la persistencia en PersistenceService
// y añade métodos de consulta de alto nivel.

import Foundation

/// Proporciona acceso de lectura y escritura al historial de monitorización.
final class HistoryRepository: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = HistoryRepository()

    private let persistence = PersistenceService()
    private init() {}

    // MARK: - Escritura

    /// Guarda un nuevo registro en el historial.
    func save(_ record: HistoricalRecord) async {
        await persistence.append(record)
    }

    // MARK: - Lectura

    /// Devuelve los registros de los últimos N días.
    func fetchLast(days: Int) async -> [HistoricalRecord] {
        await persistence.fetchRecords(lastDays: days)
    }

    /// Devuelve los registros desde una fecha concreta (p. ej. últimas 12 h).
    func fetchSince(_ date: Date) async -> [HistoricalRecord] {
        await persistence.fetchRecords(since: date)
    }

    /// Devuelve los registros de hoy.
    func fetchToday() async -> [HistoricalRecord] {
        await fetchLast(days: 1)
    }

    /// Devuelve los registros de la última semana.
    func fetchLastWeek() async -> [HistoricalRecord] {
        await fetchLast(days: 7)
    }

    // MARK: - Cálculo de medias

    /// Calcula la tasa media de consumo de los últimos N días en %/hora.
    func averageConsumptionRate(lastDays days: Int) async -> Double? {
        let records = await fetchLast(days: days)
        let rates = records.compactMap(\.ratePerHour)
        guard !rates.isEmpty else { return nil }
        return rates.reduce(0, +) / Double(rates.count)
    }

    // MARK: - Limpieza

    /// Elimina registros más antiguos que la retención configurada.
    func cleanOldRecords() async {
        let retentionDays = SettingsRepository.shared.historyRetentionDays
        await persistence.deleteRecordsOlderThan(days: retentionDays)
    }

    /// Fuerza la escritura de datos en espera al disco.
    func flush() async {
        await persistence.flushBuffer()
    }
}
