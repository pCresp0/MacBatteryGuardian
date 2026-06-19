// SettingsInfoButton.swift
// Icono (i) con explicación al pasar el cursor (popover + tooltip nativo).

import SwiftUI

struct SettingsInfoButton: View {

    let text: String
    @State private var isVisible = false
    @State private var showTask: Task<Void, Never>?
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: isVisible ? "info.circle.fill" : "info.circle")
            .font(.caption)
            .foregroundStyle(isVisible ? Color.accentColor : .secondary)
            .contentShape(Rectangle().inset(by: -6))
            .onHover { hovering in
                if hovering {
                    scheduleShow()
                } else {
                    scheduleHide()
                }
            }
            .help(text)
            .accessibilityLabel("Más información")
            .popover(isPresented: $isVisible, arrowEdge: .trailing) {
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(14)
                    .onHover { hovering in
                        hideTask?.cancel()
                        if hovering {
                            isVisible = true
                        } else {
                            scheduleHide()
                        }
                    }
            }
    }

    private func scheduleShow() {
        hideTask?.cancel()
        showTask?.cancel()
        showTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await MainActor.run { isVisible = true }
        }
    }

    private func scheduleHide() {
        showTask?.cancel()
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            await MainActor.run { isVisible = false }
        }
    }
}
