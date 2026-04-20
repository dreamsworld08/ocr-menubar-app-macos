import AppKit

final class OCRResultPanelController: NSWindowController {
    private let textView = NSTextView()

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 200, y: 200, width: 560, height: 340),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.title = "OCR Result"
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.isReleasedWhenClosed = false

        super.init(window: panel)
        configureContent(in: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(text: String) {
        textView.string = text
        textView.setSelectedRange(NSRange(location: 0, length: text.utf16.count))

        window?.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(textView)
    }

    private func configureContent(in panel: NSPanel) {
        let scrollView = NSScrollView(frame: panel.contentView?.bounds ?? .zero)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 12, height: 12)

        scrollView.documentView = textView
        panel.contentView?.addSubview(scrollView)
    }
}
