// MainWindowSizing.swift
// Ajuste dinámico de la altura de la ventana principal según la pestaña activa.

import AppKit
import SwiftUI

enum MainWindowSizer {
    static let windowWidth: CGFloat = 900
    static let tabBarHeight: CGFloat = 78
    static let minWindowHeight: CGFloat = 560
    /// Alto preferido del cuerpo en Ajustes para ver todas las secciones sin scroll.
    static let settingsPreferredBodyHeight: CGFloat = 820

    @MainActor
    static func preferredBodyHeight(for tab: AppTab) -> CGFloat? {
        switch tab {
        case .settings: return settingsPreferredBodyHeight
        default: return nil
        }
    }

    @MainActor
    static func resolvedBodyHeight(measured: CGFloat, for tab: AppTab) -> CGFloat {
        guard let preferred = preferredBodyHeight(for: tab) else { return measured }
        return max(measured, preferred)
    }

    @MainActor
    static func maxBodyHeight(for window: NSWindow?) -> CGFloat {
        let screen = window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let titleBar = window.map { $0.frame.height - $0.contentLayoutRect.height } ?? 28
        return max(320, screen.height * 0.92 - tabBarHeight - titleBar)
    }

    static func requestResize(bodyHeight: CGFloat, tab: AppTab, animated: Bool = false) {
        NotificationCenter.default.post(
            name: .mainWindowResizeToContent,
            object: nil,
            userInfo: [
                MainWindowResizePayload.bodyHeightKey: bodyHeight,
                MainWindowResizePayload.tabKey: tab.rawValue,
                MainWindowResizePayload.animatedKey: animated
            ]
        )
    }
}

enum MainWindowResizePayload {
    static let bodyHeightKey = "bodyHeight"
    static let tabKey = "tab"
    static let animatedKey = "animated"
}

extension Notification.Name {
    static let mainWindowResizeToContent = Notification.Name("com.macbatteryguardian.mainWindowResizeToContent")
}

// MARK: - Medición de contenido

private struct TabBodyHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Envuelve el cuerpo de una pestaña: mide su alto y activa scroll solo si no cabe en pantalla.
struct AdaptiveTabScrollView<Content: View>: View {
    let tab: AppTab
    @ViewBuilder var content: () -> Content

    @State private var measuredHeights: [AppTab: CGFloat] = [:]
    @State private var scrollNeeded: [AppTab: Bool] = [:]

    private var useScroll: Bool {
        scrollNeeded[tab] ?? false
    }

    var body: some View {
        Group {
            if useScroll {
                ScrollView {
                    content()
                        .background(heightReader)
                }
                .frame(height: maxBodyHeight)
            } else {
                content()
                    .background(heightReader)
            }
        }
        .onPreferenceChange(TabBodyHeightKey.self) { height in
            guard height > 1 else { return }
            measuredHeights[tab] = height
            let limit = maxBodyHeight
            let contentHeight = MainWindowSizer.resolvedBodyHeight(measured: height, for: tab)
            let needsScroll = contentHeight > limit + 1
            scrollNeeded[tab] = needsScroll
            MainWindowSizer.requestResize(
                bodyHeight: needsScroll ? limit : contentHeight,
                tab: tab,
                animated: false
            )
        }
        .onChange(of: tab) { _, newTab in
            applyPreferredLayout(for: newTab)
            applyCachedLayout(for: newTab)
        }
        .onAppear {
            applyPreferredLayout(for: tab)
        }
    }

    private func applyPreferredLayout(for tab: AppTab) {
        guard let preferred = MainWindowSizer.preferredBodyHeight(for: tab) else { return }
        let limit = maxBodyHeight
        MainWindowSizer.requestResize(
            bodyHeight: min(preferred, limit),
            tab: tab,
            animated: false
        )
    }

    private func applyCachedLayout(for tab: AppTab) {
        guard let height = measuredHeights[tab], height > 1 else { return }
        let limit = maxBodyHeight
        let contentHeight = MainWindowSizer.resolvedBodyHeight(measured: height, for: tab)
        let needsScroll = scrollNeeded[tab] ?? false
        MainWindowSizer.requestResize(
            bodyHeight: needsScroll ? limit : contentHeight,
            tab: tab,
            animated: false
        )
    }

    private var maxBodyHeight: CGFloat {
        MainWindowSizer.maxBodyHeight(for: NSApp.keyWindow)
    }

    private var heightReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: TabBodyHeightKey.self, value: proxy.size.height)
        }
    }
}
