// MainWindowChrome.swift
// Apariencia de la ventana principal: barra de título legible y arrastre.

import AppKit

enum MainWindowChrome {

    @MainActor
    static func configure(_ window: NSWindow) {
        window.title = "MacBatteryGuardian"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .shadow
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.styleMask.insert(.fullSizeContentView)

        let toolbar = NSToolbar(identifier: NSToolbar.Identifier("MainWindowToolbar"))
        toolbar.displayMode = .iconOnly
        toolbar.showsBaselineSeparator = true
        window.toolbar = toolbar
        window.toolbarStyle = .unified
    }
}
