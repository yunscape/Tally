import Foundation
import NaturalLanguage
import SwiftData

class VaultIntelligenceEngine {
    static let shared = VaultIntelligenceEngine()

    private let embedding = NLEmbedding.wordEmbedding(for: .english)
    
    private init() {}
    
    func processArtifact(vendor: String, amount: Double, existingClusters: [VaultCluster]) -> String {
        let slmProposedTag = simulateSLMReasoning(vendor: vendor, amount: amount)

        guard let embedding = embedding else { return slmProposedTag }
        
        var closestMatch: String? = nil
        var shortestDistance: Double = 1.0
        
        for cluster in existingClusters {
            let distance = embedding.distance(between: slmProposedTag.lowercased(), and: cluster.name.lowercased())
            
            if distance < shortestDistance {
                shortestDistance = distance
                closestMatch = cluster.name
            }
        }

        if shortestDistance < 0.4, let perfectMatch = closestMatch {
            return perfectMatch
        } else {
            return slmProposedTag.capitalized
        }
    }
    
    private func simulateSLMReasoning(vendor: String, amount: Double) -> String {
        let v = vendor.lowercased()
        if v.contains("apple") || v.contains("maxbhi") { return "Hardware" }
        if v.contains("aws") || v.contains("figma") || v.contains("adobe") { return "Software" }
        if v.contains("hotel") || v.contains("decathlon") { return "Travel & Lifestyle" }
        if v.contains("mamagoto") || v.contains("cafe") { return "Dining" }
        return "Miscellaneous"
    }
}
