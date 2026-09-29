import Foundation
import NaturalLanguage
import SwiftData

class VaultIntelligenceEngine {
    static let shared = VaultIntelligenceEngine()
    
    // Loads Apple's native on-device word embeddings
    private let embedding = NLEmbedding.wordEmbedding(for: .english)
    
    private init() {}
    
    /// Analyzes the vendor and routes it through the Semantic Anchor
    func processArtifact(vendor: String, amount: Double, existingClusters: [VaultCluster]) -> String {
        // 1. Simulated On-Device SLM Proposal
        // In a full production environment, this would be a Core ML / MLX Vision-Language Model
        let slmProposedTag = simulateSLMReasoning(vendor: vendor, amount: amount)
        
        // 2. The Snap-to-Grid Constraint System
        guard let embedding = embedding else { return slmProposedTag }
        
        var closestMatch: String? = nil
        var shortestDistance: Double = 1.0
        
        for cluster in existingClusters {
            // No conditional unwrapping required since distance is a guaranteed Double
            let distance = embedding.distance(between: slmProposedTag.lowercased(), and: cluster.name.lowercased())
            
            if distance < shortestDistance {
                shortestDistance = distance
                closestMatch = cluster.name
            }
        }
        
        // If the AI's concept is mathematically closer than 0.4 to an existing cluster, snap it to the grid.
        if shortestDistance < 0.4, let perfectMatch = closestMatch {
            return perfectMatch
        } else {
            // Only authorize a completely new root tag if it is mathematically distinct
            return slmProposedTag.capitalized
        }
    }
    
    private func simulateSLMReasoning(vendor: String, amount: Double) -> String {
        let v = vendor.lowercased()
        // Evaluates for PC rigging or standard parts
        if v.contains("apple") || v.contains("maxbhi") { return "Hardware" }
        if v.contains("aws") || v.contains("figma") || v.contains("adobe") { return "Software" }
        if v.contains("hotel") || v.contains("decathlon") { return "Travel & Lifestyle" }
        if v.contains("mamagoto") || v.contains("cafe") { return "Dining" }
        return "Miscellaneous"
    }
}
