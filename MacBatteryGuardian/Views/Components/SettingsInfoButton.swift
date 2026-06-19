// SettingsInfoButton.swift
// Botón (i) que muestra la explicación al pulsar (popover).

import SwiftUI

struct SettingsInfoButton: View {

    let text: String
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: isPresented ? "info.circle.fill" : "info.circle")
                .font(.caption)
                .foregroundStyle(isPresented ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Más información")
        .popover(isPresented: $isPresented, arrowEdge: .trailing) {
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(14)
        }
    }
}
