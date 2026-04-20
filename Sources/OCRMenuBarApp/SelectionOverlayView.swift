import AppKit

final class SelectionOverlayView: NSView {
    var onCompleteSelection: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        startPoint = location
        currentPoint = location
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard startPoint != nil else { return }
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let selection = selectionRect(), selection.width > 8, selection.height > 8 else {
            onCancel?()
            return
        }

        onCompleteSelection?(selection)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.24).setFill()
        bounds.fill()

        guard let selection = selectionRect() else {
            drawInstruction()
            return
        }

        NSGraphicsContext.saveGraphicsState()
        NSColor.clear.setFill()
        selection.fill(using: .clear)
        NSGraphicsContext.restoreGraphicsState()

        let border = NSBezierPath(rect: selection)
        border.lineWidth = 2
        NSColor.systemYellow.setStroke()
        border.stroke()

        drawInstruction()
    }

    private func selectionRect() -> CGRect? {
        guard let startPoint, let currentPoint else { return nil }

        return CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }

    private func drawInstruction() {
        let instruction = "Drag to highlight text area. Release to copy OCR. Press Esc to cancel."
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: NSColor.white
        ]

        let attributedText = NSAttributedString(string: instruction, attributes: attributes)
        let textSize = attributedText.size()
        let textPoint = CGPoint(x: (bounds.width - textSize.width) / 2, y: bounds.height - textSize.height - 40)

        attributedText.draw(at: textPoint)
    }
}
