import AppKit

@MainActor
final class SelectionOverlayView: NSView {
    var onCompleteSelection: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var dragStartPoint: CGPoint?
    private var dragCurrentPoint: CGPoint?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragStartPoint = point
        dragCurrentPoint = point
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragStartPoint != nil else { return }
        dragCurrentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentSelectionRect(), rect.width >= 8, rect.height >= 8 else {
            onCancel?()
            return
        }

        onCompleteSelection?(rect)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.22).setFill()
        bounds.fill()

        if let selection = currentSelectionRect() {
            NSGraphicsContext.saveGraphicsState()
            NSColor.clear.setFill()
            selection.fill(using: .clear)
            NSGraphicsContext.restoreGraphicsState()

            let borderPath = NSBezierPath(rect: selection)
            borderPath.lineWidth = 2
            NSColor.systemYellow.setStroke()
            borderPath.stroke()
        }

        drawInstructionText()
    }

    private func currentSelectionRect() -> CGRect? {
        guard let start = dragStartPoint, let end = dragCurrentPoint else { return nil }

        return CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func drawInstructionText() {
        let text = "Drag to highlight text. Release to OCR and copy. Press Esc to cancel."
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: NSColor.white
        ]

        let attributed = NSAttributedString(string: text, attributes: attributes)
        let size = attributed.size()
        let origin = CGPoint(x: (bounds.width - size.width) * 0.5, y: bounds.height - size.height - 40)

        attributed.draw(at: origin)
    }
}
