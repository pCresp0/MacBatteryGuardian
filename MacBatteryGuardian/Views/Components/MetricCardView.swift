// MetricCardView.swift
// Tarjeta contenedora reutilizable con título e ícono para las secciones de la UI.

import SwiftUI

struct MetricCardView<Content: View, Footer: View>: View {

    let title: String
    let icon: String
    let iconColor: Color
    var destinationTab: AppTab?
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    init(
        title: String,
        icon: String,
        iconColor: Color,
        destinationTab: AppTab? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.destinationTab = destinationTab
        self.content = content
        self.footer = footer
    }

    private var hasFooter: Bool {
        Footer.self != EmptyView.self
    }

    private var isNavigable: Bool {
        destinationTab != nil
    }

    var body: some View {
        Group {
            if let tab = destinationTab, !hasFooter {
                Button {
                    MainWindowNavigation.select(tab: tab)
                } label: {
                    cardContent
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .buttonStyle(MetricCardButtonStyle(accent: iconColor))
            } else {
                cardBody
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var cardContent: some View {
        cardBody
            .contentShape(RoundedRectangle(cornerRadius: LiquidGlassTokens.cardRadius, style: .continuous))
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let tab = destinationTab, hasFooter {
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        MainWindowNavigation.select(tab: tab)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            cardHeader
                            content()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(
                            RoundedRectangle(cornerRadius: LiquidGlassTokens.compactRadius, style: .continuous)
                        )
                    }
                    .buttonStyle(MetricCardZoneButtonStyle(accent: iconColor))

                    Divider().opacity(0.35)

                    footer()
                }
            } else if destinationTab == nil {
                cardHeader
                content()
                footer()
            } else {
                cardHeader
                content()
                footer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .liquidGlassCard(interactive: isNavigable && !hasFooter)
    }

    private var cardHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            if destinationTab != nil {
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Abrir")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

extension MetricCardView where Footer == EmptyView {
    init(
        title: String,
        icon: String,
        iconColor: Color,
        destinationTab: AppTab? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title: title,
            icon: icon,
            iconColor: iconColor,
            destinationTab: destinationTab,
            content: content,
            footer: { EmptyView() }
        )
    }
}

// MARK: - Estilo clicable (General, etc.)

private struct MetricCardButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        MetricCardButtonBody(configuration: configuration, accent: accent)
    }
}

private struct MetricCardButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let accent: Color
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .navigableCardHighlight(
                accent: accent,
                isHovered: isHovered,
                isPressed: configuration.isPressed
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

/// Zona navegable dentro de una tarjeta con pie (p. ej. Modo de energía).
private struct MetricCardZoneButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        MetricCardZoneButtonBody(configuration: configuration, accent: accent)
    }
}

private struct MetricCardZoneButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let accent: Color
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .selectableCellHighlight(
                accent: accent,
                isHovered: isHovered,
                isPressed: configuration.isPressed,
                cornerRadius: LiquidGlassTokens.compactRadius
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

#Preview {
    MetricCardView(title: "Batería", icon: "battery.100", iconColor: .green, destinationTab: .battery) {
        Text("78%")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(.green)
    }
    .frame(width: 200)
    .padding()
    .appCanvasBackground()
}
