import CoreGraphics
import Vision

enum OCRError: LocalizedError {
    case noText

    var errorDescription: String? {
        switch self {
        case .noText:
            "No text detected in the selected area."
        }
    }
}

enum OCREngine {
    static func recognizeText(from image: CGImage) throws -> String {
        var resultText: String = ""
        var capturedError: Error?

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                capturedError = error
                return
            }

            let observations = (request.results as? [VNRecognizedTextObservation]) ?? []

            let lines = observations
                .sorted { lhs, rhs in
                    let sameLineThreshold: CGFloat = 0.015
                    let yDelta = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)

                    if yDelta > sameLineThreshold {
                        return lhs.boundingBox.midY > rhs.boundingBox.midY
                    }

                    return lhs.boundingBox.minX < rhs.boundingBox.minX
                }
                .compactMap { $0.topCandidates(1).first?.string }

            resultText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = Locale.preferredLanguages

        if #available(macOS 13.0, *) {
            request.automaticallyDetectsLanguage = true
        }

        if #available(macOS 14.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
        }

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        if let capturedError {
            throw capturedError
        }

        guard !resultText.isEmpty else {
            throw OCRError.noText
        }

        return resultText
    }
}
