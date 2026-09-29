import Foundation
import Vision

class OCRService {
    static let shared = OCRService()
    
    func processImage(_ cgImage: CGImage) async -> (vendor: String, amount: Double) {
        return await Task.detached(priority: .userInitiated) {
            return await withCheckedContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                        continuation.resume(returning: ("Unknown Vendor", 0.0))
                        return
                    }
                    
                    let textLines = observations.compactMap { $0.topCandidates(1).first?.string }
                    
                    var vendor = "Maxbhi.com"
                    var amount: Double = 0.0
                    
                    if let firstLine = textLines.first, !firstLine.isEmpty {
                        vendor = firstLine
                    }
                    for line in textLines.reversed() {
                        let cleanLine = line.replacingOccurrences(of: "$", with: "")
                                            .trimmingCharacters(in: .whitespaces)
                        
                        if let price = Double(cleanLine) {
                            amount = price
                            break
                        }
                    }
                    
                    continuation.resume(returning: (vendor, amount))
                }
                
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: ("Unknown Vendor", 0.0))
                }
            }
        }.value
    }
}
