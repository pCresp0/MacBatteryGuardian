// LiquidGlassStyle.swift
// Sistema visual Liquid Glass (macOS 26+) con fallback translúcido en macOS 14+.

import SwiftUI

// MARK: - Tokens

enum LiquidGlassTokens {
    static let cardRadius: CGFloat = 16
    static let chromeRadius: CGFloat = 14
    static let compactRadius: CGFloat = 12
    static let insetRadius: CGFloat = 10
    static let cellRadius: CGFloat = 10
}

// MARK: - Fondo de lienzo

struct AppCanvasBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(colorScheme == .dark ? 0.55 : 0.35)

            RadialGradient(
                colors: [
                    Color.green.opacity(colorScheme == .dark ? 0.12 : 0.08),
                    .clear
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 420
            )

            RadialGradient(
                colors: [
                    Color.blue.opacity(colorScheme == .dark ? 0.1 : 0.06),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 380
            )

            // Franja bajo la barra de título del sistema para legibilidad
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.regularMaterial)
                    .overlay(alignment: .bottom) {
                        Divider().opacity(colorScheme == .dark ? 0.35 : 0.25)
                    }
                    .frame(height: 46)
                Spacer(minLength: 0)
            }
        }
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.1, blue: 0.14),
                Color(red: 0.06, green: 0.08, blue: 0.11),
                Color(red: 0.05, green: 0.07, blue: 0.1)
            ]
        }
        return [
            Color(red: 0.94, green: 0.96, blue: 0.99),
            Color(red: 0.9, green: 0.94, blue: 0.98),
            Color(red: 0.88, green: 0.92, blue: 0.97)
        ]
    }
}

// MARK: - Modifiers

private struct LiquidGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(
                interactive ? Glass.regular.interactive() : .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.07), radius: 10, y: 4)
        }
    }
}

private struct LiquidGlassInsetModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.045))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5)
            }
    }
}

// MARK: - View extensions

extension View {

    func appCanvasBackground() -> some View {
        background { AppCanvasBackground() }
    }

    func liquidGlassCard(interactive: Bool = false) -> some View {
        modifier(LiquidGlassSurfaceModifier(
            cornerRadius: LiquidGlassTokens.cardRadius,
            interactive: interactive
        ))
    }

    func liquidGlassChrome(interactive: Bool = true) -> some View {
        modifier(LiquidGlassSurfaceModifier(
            cornerRadius: LiquidGlassTokens.chromeRadius,
            interactive: interactive
        ))
    }

    func liquidGlassCell(interactive: Bool = false) -> some View {
        modifier(LiquidGlassSurfaceModifier(
            cornerRadius: LiquidGlassTokens.cellRadius,
            interactive: interactive
        ))
    }

    /// Relleno interior (sin vidrio) para evitar capas de glass anidadas.
    func liquidGlassInset(cornerRadius: CGFloat = LiquidGlassTokens.insetRadius) -> some View {
        modifier(LiquidGlassInsetModifier(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    func glassEffectContainer(spacing: CGFloat, @ViewBuilder content: () -> some View) -> some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing, content: content)
        } else {
            content()
        }
    }

    @ViewBuilder
    func popoverChromeBackground() -> some View {
        if #available(macOS 26.0, *) {
            self.background(.clear)
        } else {
            self.background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    func liquidGlassProminentButton() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    func liquidGlassBorderedButton() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }

    /// Separador sutil entre secciones (popover, paneles).
    func liquidGlassSectionDivider() -> some View {
        Divider().opacity(0.45)
    }

    /// Resaltado estable para celdas clicables (popover). Sin togglear glass en hover.
    func selectableCellHighlight(
        accent: Color,
        isHovered: Bool,
        isPressed: Bool,
        cornerRadius: CGFloat = LiquidGlassTokens.cellRadius
    ) -> some View {
        let active = isHovered || isPressed
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return background {
            shape.fill(accent.opacity(active ? (isPressed ? 0.14 : 0.09) : 0.04))
        }
        .overlay {
            shape.strokeBorder(
                accent.opacity(active ? (isPressed ? 0.42 : 0.28) : 0.14),
                lineWidth: 0.75
            )
        }
    }

    /// Resaltado para tarjetas navegables (General). Siempre indica que es clicable.
    func navigableCardHighlight(
        accent: Color,
        isHovered: Bool,
        isPressed: Bool,
        cornerRadius: CGFloat = LiquidGlassTokens.cardRadius
    ) -> some View {
        let active = isHovered || isPressed
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return overlay {
            shape
                .fill(accent.opacity(active ? (isPressed ? 0.12 : 0.08) : 0.03))
                .allowsHitTesting(false)
        }
        .overlay {
            shape.strokeBorder(
                accent.opacity(active ? (isPressed ? 0.55 : 0.42) : 0.2),
                lineWidth: active ? 1.5 : 1
            )
            .allowsHitTesting(false)
        }
        .shadow(
            color: accent.opacity(isHovered ? 0.22 : 0),
            radius: isHovered ? 10 : 0,
            y: 3
        )
    }
}
