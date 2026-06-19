// PersistenceService.swift
// Servicio de persistencia que guarda registros históricos en archivos JSON diarios
// en ~/Library/Application Support/MacBatteryGuardian/.

import Foundation
import OSLog

/// Persiste y recupera registros históricos usando archivos JSON rotados por día.
actor PersistenceService {

    private let logger = Logger(subsystem: Constants.Bundle.appIdentifier, category: "PersistenceService")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var writeBuffer: [HistoricalRecord] = []
    private let bufferFlushThreshold = 12  // Escribir a disco tras 12 registros (~1 hora)

    // MARK: - Directorio base

    private var baseDirectory: URL {
        get throws {
            let support = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dir = support.appendingPathComponent(Constants.History.applicationSupportFolder)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }
    }

    // MARK: - Escritura

    /// Añade un registro al buffer. Lo escribe a disco si el buffer supera el umbral.
    func append(_ record: HistoricalRecord) async {
        writeBuffer.append(record)
        if writeBuffer.count >= bufferFlushThreshold {
            await flushBuffer()
        }
    }

    /// Fuerza la escritura del buffer a disco.
    func flushBuffer() async {
        guard !writeBuffer.isEmpty else { return }
        let toWrite = writeBuffer
        writeBuffer.removeAll()

        do {
            try await writeRecords(toWrite)
        } catch {
            logger.error("PersistenceService: Error al escribir historial: \(error.localizedDescription)")
            // Devolver al buffer para reintentar
            writeBuffer.insert(contentsOf: toWrite, at: 0)
        }
    }

    // MARK: - Lectura

    /// Lee todos los registros de los últimos N días.
    func fetchRecords(lastDays days: Int) async -> [HistoricalRecord] {
        var allRecords: [HistoricalRecord] = []
        for offset in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let records = await readRecords(for: date)
            allRecords.append(contentsOf: records)
        }
        return allRecords.sorted { $0.timestamp < $1.timestamp }
    }

    /// Registros desde una fecha (inclusive), ordenados cronológicamente.
    func fetchRecords(since date: Date) async -> [HistoricalRecord] {
        let daySpan = max(1, Int(ceil(Date().timeIntervalSince(date) / 86_400)))
        return await fetchRecords(lastDays: daySpan).filter { $0.timestamp >= date }
    }

    // MARK: - Limpieza

    /// Elimina archivos de historial con más de N días de antigüedad.
    func deleteRecordsOlderThan(days: Int) async {
        guard let base = try? baseDirectory else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let urls = (try? FileManager.default.contentsOfDirectory(
            at: base,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )) ?? []

        for url in urls {
            guard url.pathExtension == "json",
                  let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let creationDate = attributes[.creationDate] as? Date,
                  creationDate < cutoff else {
                continue
            }
            try? FileManager.default.removeItem(at: url)
            logger.debug("PersistenceService: Eliminado historial antiguo: \(url.lastPathComponent).")
        }
    }

    // MARK: - Privado

    private func fileURL(for date: Date) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let fileName = "\(Constants.History.historyFileName)-\(formatter.string(from: date)).json"
        return try baseDirectory.appendingPathComponent(fileName)
    }

    private func writeRecords(_ records: [HistoricalRecord]) async throws {
        // Agrupa por día para escribir en el archivo correcto
        let grouped = Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.timestamp)
        }

        for (day, dayRecords) in grouped {
            let url = try fileURL(for: day)
            var existing = await readRecords(for: day)
            existing.append(contentsOf: dayRecords)
            let data = try encoder.encode(existing)
            try data.write(to: url, options: .atomic)
        }
    }

    private func readRecords(for date: Date) async -> [HistoricalRecord] {
        guard let url = try? fileURL(for: date),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let records = try? decoder.decode([HistoricalRecord].self, from: data) else {
            return []
        }
        return records
    }
}
