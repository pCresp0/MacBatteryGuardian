// MenuBarIconRenderer.swift
// Icono de menubar ancho y nítido (@1x/@2x): batería + lupa.

import AppKit

enum MenuBarIconRenderer {

    /// Canvas más ancho que alto — mejor legibilidad en la barra de menú.
    private static let canvasWidth: CGFloat = 26
    private static let canvasHeight: CGFloat = 16

    static var canvasSize: NSSize {
        NSSize(width: canvasWidth, height: canvasHeight)
    }

    /// Icono template para NSStatusItem.
    static func makeStatusItemImage() -> NSImage {
        let image = NSImage(size: canvasSize)

        for scale in [1, 2] {
            let pixelsW = Int(canvasWidth * CGFloat(scale))
            let pixelsH = Int(canvasHeight * CGFloat(scale))
            guard let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelsW,
                pixelsHigh: pixelsH,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else { continue }

            rep.size = canvasSize

            NSGraphicsContext.saveGraphicsState()
            if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
                NSGraphicsContext.current = ctx
                ctx.imageInterpolation = .high
                NSColor.clear.set()
                NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight).fill()
                drawComposite()
            }
            NSGraphicsContext.restoreGraphicsState()
            image.addRepresentation(rep)
        }

        image.isTemplate = true
        return image
    }

    // MARK: - Dibujo

    private static func drawComposite() {
        let batteryCfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        guard let battery = NSImage(systemSymbolName: "battery.75percent", accessibilityDescription: nil)?
            .withSymbolConfiguration(batteryCfg) else { return }

        let magCfg = NSImage.SymbolConfiguration(pointSize: 6.5, weight: .heavy)
        guard let magnifier = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)?
            .withSymbolConfiguration(magCfg) else { return }

        // Batería ocupa la mayor parte del ancho
        battery.draw(in: NSRect(x: 0, y: 1.5, width: 20, height: 13))
        magnifier.draw(in: NSRect(x: 16, y: 0.5, width: 9, height: 9))
    }
}
