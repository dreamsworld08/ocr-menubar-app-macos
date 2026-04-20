import CoreGraphics
import Vision

enum OCRError: LocalizedError {
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .noTextFound:
            "No text detected in the selected area."
        }
    }
}

enum OCREngine {
    static func recognizeText(from image: CGImage) throws -> String {
        var capturedResult: Result<String, Error>?

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                capturedResult = .failure(error)
                return
            }

            let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
            let text = Self.buildText(from: observations)

            if text.isEmpty {
                capturedResult = .failure(OCRError.noTextFound)
            } else {
                capturedResult = .success(text)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = Locale.preferredLanguages

        if #available(macOS 14.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
        }

        if #available(macOS 13.0, *) {
            request.automaticallyDetectsLanguage = true
        }

        do {
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try handler.perform([request])
        } catch {
            throw error
        }

        switch capturedResult {
        case let .success(text):
            return text
        case let .failure(error):
            throw error
        case .none:
            throw OCRError.noTextFound
        }
    }

    private static func buildText(from observations: [VNRecognizedTextObservation]) -> String {
        let sorted = observations.sorted { lhs, rhs in
            let sameLineThreshold: CGFloat = 0.015
            let yDelta = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)

            if yDelta > sameLineThreshold {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }

            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }

        return sorted.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
