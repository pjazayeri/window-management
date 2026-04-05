import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        requestAccessibilityIfNeeded()
        HotKeyManager.shared.registerAll()
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.3.group",
                accessibilityDescription: "Window Manager"
            )
        }

        let menu = NSMenu()

        let title = NSMenuItem(title: "WindowManager", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        menu.addItem(
            NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        )

        statusItem?.menu = menu
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Accessibility

    private func requestAccessibilityIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if !trusted {
            // System has shown the System Preferences prompt.
            // The hotkeys will silently no-op until access is granted.
        }
    }
}
