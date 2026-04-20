import AppKit

@MainActor
final class StatusBarController {
    private let coordinator: OCRCoordinator
    private let statusItem: NSStatusItem

    init(coordinator: OCRCoordinator) {
        self.coordinator = coordinator
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupStatusItem()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "OCR") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "OCR"
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start OCR", action: #selector(startOCR), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func startOCR() {
        coordinator.startSelectionFlow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
