// MemoryViewModel.swift
// ViewModel para la pestaña de Memoria en la ventana principal.

import Foundation
import SwiftUI

@MainActor
final class MemoryViewModel: ObservableObject {

    @Published private(set) var totalFormatted: String = "–"
    @Published private(set) var usedFormatted: String  = "–"
    @Published private(set) var freeFormatted: String  = "–"
    @Published private(set) var wiredFormatted: String = "–"
    @Published private(set) var compressedFormatted: String = "–"
    @Published private(set) var usedPercent: Double = 0
    @Published private(set) var pressureLevel: MemoryPressureLevel = .nominal
    @Published private(set) var pressureColor: Color = .green
    @Published private(set) var pressureRatio: Double = 0
    @Published private(set) var memoryBarSegments: [MemoryBarSegment] = []

    // Historial en vivo para gráfica temporal
    @Published private(set) var memoryTimeline: [TimelineSample] = []
    private let maxTimelinePoints = 120

    func update(system: SystemSnapshot?) {
        guard let system else { return }

        totalFormatted      = system.totalMemoryBytes.bytesFormatted
        usedFormatted       = system.usedMemoryBytes.bytesFormatted
        freeFormatted       = system.freeMemoryBytes.bytesFormatted
        wiredFormatted      = system.wiredMemoryBytes.bytesFormatted
        compressedFormatted = system.compressedMemoryBytes.bytesFormatted
        usedPercent         = system.usedMemoryPercent
        pressureRatio       = system.memoryPressureRatio
        pressureLevel       = system.memoryPressureLevel
        pressureColor       = .memoryPressureColor(system.memoryPressureLevel)
        memoryBarSegments   = Self.buildBarSegments(from: system)

        TimelineHistory.append(system.usedMemoryPercent, to: &memoryTimeline, maxPoints: maxTimelinePoints)
    }

    private static func buildBarSegments(from system: SystemSnapshot) -> [MemoryBarSegment] {
        let total = Double(system.totalMemoryBytes)
        guard total > 0 else { return [] }

        let wired = system.wiredMemoryBytes
        let compressed = system.compressedMemoryBytes
        let active = system.usedMemoryBytes > wired + compressed
            ? system.usedMemoryBytes - wired - compressed
            : 0
        let cached = system.inactiveMemoryBytes
        let free = system.freeMemoryBytes
        let available = cached + free

        func segment(
            id: String,
            label: String,
            bytes: UInt64,
            color: Color,
            showInBar: Bool = true
        ) -> MemoryBarSegment {
            MemoryBarSegment(
                id: id,
                label: label,
                formatted: bytes.bytesFormatted,
                color: color,
                fraction: Double(bytes) / total,
                showInBar: showInBar
            )
        }

        var items: [MemoryBarSegment] = [
            segment(id: "wired", label: "Bloqueada (Wired)", bytes: wired, color: .red),
            segment(id: "compressed", label: "Comprimida", bytes: compressed, color: .orange),
            segment(id: "active", label: "Apps (activa)", bytes: active, color: .purple),
            segment(
                id: "available",
                label: "Disponible",
                bytes: available,
                color: Color.primary.opacity(0.1)
            )
        ]

        if cached > 0 {
            items.append(segment(
                id: "cached",
                label: "Caché (recuperable)",
                bytes: cached,
                color: .yellow.opacity(0.85),
                showInBar: false
            ))
        }

        items.append(segment(
            id: "free",
            label: "Libre",
            bytes: free,
            color: Color.primary.opacity(0.12),
            showInBar: false
        ))

        return items
    }
}
