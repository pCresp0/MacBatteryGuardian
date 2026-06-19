// BatteryAutonomySummaryView.swift
// Autonomía y hora estimada de agotamiento (General, Batería…).

import SwiftUI

struct BatteryAutonomySummaryView: View {

    let autonomySentence: String?
    let depletionSentence: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let autonomySentence {
                Text(autonomySentence)
            }
            if let depletionSentence {
                Text(depletionSentence)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
}
