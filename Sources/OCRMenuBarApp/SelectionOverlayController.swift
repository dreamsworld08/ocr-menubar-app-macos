import AppKit

@MainActor
final class SelectionOverlayController {
    var onSelection: ((CGRect) -> Void)?

    private var overlayWindow: SelectionOverlayWindow?
    private var localKeyMonitor: Any?

    func presentSelectionOverlay() {
        guard overlayWindow == nil else { return }

        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main

        guard let screen = targetScreen else { return }

        let window = SelectionOverlayWindow(frame: screen.frame)
        let overlayView = SelectionOverlayView(frame: window.contentView?.bounds ?? .zero)
        overlayView.autoresizingMask = [.width, .height]

        overlayView.onCancel = { [weak self] in
            self?.teardown()
        }

        overlayView.onCompleteSelection = { [weak self] localRect in
            self?.finishSelection(localRect, from: window)
        }

        window.contentView = overlayView
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        NSCursor.iBeam.push()

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.teardown()
                return nil
            }
            return event
        }

        overlayWindow = window
    }

    private func finishSelection(_ localRect: CGRect, from window: NSWindow) {
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
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }

        if overlayWindow != nil {
            NSCursor.pop()
        }

        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}

@MainActor
final class SelectionOverlayWindow: NSWindow {
    init(frame: CGRect) {
        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)

        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovable = false
        isMovableByWindowBackground = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
