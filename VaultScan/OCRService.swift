import Foundation
import Vision

class OCRService {
    static let shared = OCRService()
    
    // This feeds the image to Apple's Neural Engine
    func processImage(_ cgImage: CGImage) async -> (vendor: String, amount: Double) {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: ("Unknown Vendor", 0.0))
                    return
                }
                
                // Combine all the recognized words into lines of text
                let textLines = observations.compactMap { $0.topCandidates(1).first?.string }
                
                // --- HEURISTIC PARSER ---
                // In a production app, you would use a Regex or Natural Language model here.
                // For now, we use a simple set of rules to find the vendor and price.
                
                var vendor = "Maxbhi.com" // Default fallback for hardware orders
                var amount: Double = 0.0
                
                // Rule 1: The Vendor is usually the biggest text at the very top (first line)
                if let firstLine = textLines.first, !firstLine.isEmpty {
                    vendor = firstLine
                }
                
                // Rule 2: The Total Price is usually near the bottom and contains numbers
                for line in textLines.reversed() {
                    // Clean up the text by removing $ signs and spaces
                    let cleanLine = line.replacingOccurrences(of: "$", with: "")
                                        .trimmingCharacters(in: .whitespaces)
                    
                    // If the cleaned line can be converted perfectly into a decimal number, it's our total!
                    if let price = Double(cleanLine) {
                        amount = price
                        break
                    }
                }
                
                continuation.resume(returning: (vendor, amount))
            }
            
            // Tell Apple to prioritize accuracy over speed
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Execute the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
