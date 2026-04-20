import AppKit

@MainActor
final class SelectionOverlayController {
    var onSelection: ((CGRect) -> Void)?

    private var overlayWindow: SelectionOverlayWindow?
    private var keyMonitor: Any?

    func presentSelectionOverlay() {
        guard overlayWindow == nil else { return }

        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main

        guard let screen = targetScreen else { return }

        let window = SelectionOverlayWindow(screenFrame: screen.frame)
        let overlayView = SelectionOverlayView(frame: window.contentView?.bounds ?? .zero)

        overlayView.autoresizingMask = [.width, .height]
        overlayView.onCompleteSelection = { [weak self] localRect in
            self?.finish(with: localRect, in: window)
        }
        overlayView.onCancel = { [weak self] in
            self?.teardown()
        }

        window.contentView = overlayView
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        NSCursor.iBeam.push()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.teardown()
                return nil
            }
            return event
        }

        overlayWindow = window
    }

    private func finish(with localRect: CGRect, in window: NSWindow) {
        let screenRect = CGRect(
            x: window.frame.origin.x + localRect.origin.x,
            y: window.frame.origin.y + localRect.origin.y,
            width: localRect.width,
            height: localRect.height
        )

        teardown()
        onSelection?(screenRect)
    }

    private func teardown() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }

        if overlayWindow != nil {
            NSCursor.pop()
        }

        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}

final class SelectionOverlayWindow: NSWindow {
    init(screenFrame: CGRect) {
        super.init(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        isMovableByWindowBackground = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
