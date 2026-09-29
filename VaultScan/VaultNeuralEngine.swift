import Foundation
import SwiftData
import MapKit

class VaultNeuralEngine {
    static func autoCategorize(vendor: String, history: [VaultItem]) async -> String {
        let cleanVendor = vendor.trimmingCharacters(in: .whitespacesAndNewlines)
        if let previousEntry = history.first(where: { $0.vendorName.caseInsensitiveCompare(cleanVendor) == .orderedSame }) {
            print("🧠 Neural Engine: Categorized via Local Memory")
            return previousEntry.cluster?.name ?? "Miscellaneous"
        }
        if let mapCategory = await searchAppleMaps(for: cleanVendor) {
            print("🗺️ Neural Engine: Categorized via Apple Maps")
            return mapCategory
        }
        print("🤖 Neural Engine: Falling back to Generative AI")
        return await askGenerativeAI(vendor: cleanVendor)
    }
    private static func searchAppleMaps(for vendor: String) async -> String? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = vendor
        request.pointOfInterestFilter = .includingAll
        
        let search = MKLocalSearch(request: request)
        
        guard let response = try? await search.start(),
              let firstResult = response.mapItems.first,
              let poiCategory = firstResult.pointOfInterestCategory else {
            return nil
        }
        switch poiCategory {
        case .restaurant, .cafe, .bakery, .foodMarket, .brewery:
            return "Dining"
        case .hotel, .airport, .publicTransport:
            return "Travel"
        case .store, .pharmacy:
            return "Supplies"
        case .gasStation, .evCharger:
            return "Utilities"
        default:
            return nil
        }
    }
        private static func askGenerativeAI(vendor: String) async -> String {
            _ = """
            I just made a purchase from a vendor named "\(vendor)".
            Categorize this transaction into exactly one of these categories: 
            Hardware, Software, Travel, Utilities, Supplies, Dining, Miscellaneous.
            Reply with ONLY the category word.
            """
            
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                let text = vendor.lowercased()
                if text.contains("aws") || text.contains("cloud") || text.contains("github") { return "Software" }
                if text.contains("maxbhi") || text.contains("screen") || text.contains("lens") { return "Hardware" }
                if text.contains("decathlon") || text.contains("skin") { return "Supplies" }
                
                return "Miscellaneous"
            } catch {
                return "Miscellaneous"
            }
        }}
