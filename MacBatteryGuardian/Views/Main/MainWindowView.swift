// MainWindowView.swift
// Ventana principal con navegación por pestañas.

import SwiftUI

struct MainWindowView: View {

    @EnvironmentObject private var store: ViewModelStore
    @EnvironmentObject private var monitor: MonitoringManager
    @State private var selectedTab: AppTab
    @Namespace private var tabGlassNamespace

    init(initialTab: AppTab = .general) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            AdaptiveTabScrollView(tab: selectedTab) {
                tabContent
            }
        }
        .frame(width: MainWindowSizer.windowWidth)
        .fixedSize(horizontal: true, vertical: false)
        .appCanvasBackground()
        .onReceive(NotificationCenter.default.publisher(for: .selectMainWindowTab)) { notification in
            guard
                let raw = notification.userInfo?[MainWindowNavigation.tabUserInfoKey] as? String,
                let tab = AppTab(rawValue: raw)
            else { return }
            selectedTab = tab
        }
    }

    // MARK: - Barra de pestañas

    private var tabBar: some View {
        glassEffectContainer(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    tabBarButton(tab: tab)
                }
            }
            .padding(6)
        }
        .liquidGlassChrome()
    }

    private func tabBarButton(tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.sfSymbolName)
                    .font(.system(size: 16))
                Text(tab.localizedTitle)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .contentShape(RoundedRectangle(cornerRadius: LiquidGlassTokens.compactRadius, style: .continuous))
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: LiquidGlassTokens.compactRadius, style: .continuous)
                        .fill(Color.accentColor.opacity(0.22))
                }
            }
            .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
        .modifier(TabGlassSelectionModifier(isSelected: selectedTab == tab, id: tab.rawValue, namespace: tabGlassNamespace))
    }

    // MARK: - Contenido de pestañas

    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .general:  GeneralTabView()
            case .battery:  BatteryTabView()
            case .cpu:      CPUTabView()
            case .memory:   MemoryTabView()
            case .history:  HistoryTabView()
            case .health:   HealthTabView()
            case .settings: SettingsTabView()
            }
        }
    }
}

// MARK: - Pestaña seleccionada (Liquid Glass)

private struct TabGlassSelectionModifier: ViewModifier {
    let isSelected: Bool
    let id: String
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffectID(isSelected ? id : nil, in: namespace)
        } else {
            content
        }
    }
}

// MARK: - AppTab

enum AppTab: String, CaseIterable, Identifiable {
    case general  = "general"
    case battery  = "battery"
    case cpu      = "cpu"
    case memory   = "memory"
    case history  = "history"
    case health   = "health"
    case settings = "settings"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .general:  return "General"
        case .battery:  return "Batería"
        case .cpu:      return "CPU"
        case .memory:   return "Memoria RAM"
        case .history:  return "Histórico"
        case .health:   return "Salud"
        case .settings: return "Ajustes"
        }
    }

    var sfSymbolName: String {
        switch self {
        case .general:  return "square.grid.2x2"
        case .battery:  return "battery.100"
        case .cpu:      return "cpu"
        case .memory:   return "memorychip"
        case .history:  return "chart.line.uptrend.xyaxis"
        case .health:   return "heart.text.square"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Navegación desde el popover

enum MainWindowNavigation {
    static let tabUserInfoKey = "tab"

    static func open(tab: AppTab = .general) {
        NotificationCenter.default.post(
            name: .openMainWindow,
            object: nil,
            userInfo: [tabUserInfoKey: tab.rawValue]
        )
    }

    /// Cambia la pestaña activa dentro de la ventana principal (sin reabrirla).
    static func select(tab: AppTab) {
        NotificationCenter.default.post(
            name: .selectMainWindowTab,
            object: nil,
            userInfo: [tabUserInfoKey: tab.rawValue]
        )
    }
}

extension Notification.Name {
    static let selectMainWindowTab = Notification.Name("com.macbatteryguardian.selectMainWindowTab")
}
