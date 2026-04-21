import AppKit
import CoreGraphics

@MainActor
final class OCRCoordinator {
    static let shared = OCRCoordinator()

    private let overlayController = SelectionOverlayController()
    private let resultPanelController = OCRResultPanelController()

    private init() {
        overlayController.onSelection = { [weak self] selectionRect in
            self?.performOCR(for: selectionRect)
        }
    }

    func startSelectionFlow() {
        guard ScreenCapture.preflightOrRequestPermission() else {
            showPermissionHint()
            return
        }

        overlayController.presentSelectionOverlay()
    }

    private func performOCR(for rect: CGRect) {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let image = ScreenCapture.capture(rect: rect) else {
                await MainActor.run {
                    self?.showError(message: "Could not capture the selected area.")
                }
                return
            }

            do {
                let text = try OCREngine.recognizeText(from: image)
                await MainActor.run {
                    self?.copyToClipboard(text)
                    self?.resultPanelController.show(text: text)
                }
            } catch {
                await MainActor.run {
                    self?.showError(message: error.localizedDescription)
                }
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func showPermissionHint() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Needed"
        alert.informativeText = "Enable this app in System Settings > Privacy & Security > Screen Recording, then click Start OCR again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showError(message: String) {
        let alert = NSAlert()
        alert.messageText = "OCR Failed"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
