import AppIntents
import SwiftData
import Foundation

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Vault Expense"
    static var description = IntentDescription("Quickly add a new digital receipt, subscription, or bill to VaultScan.")
    
    @Parameter(title: "Vendor Name")
    var vendor: String
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Category", default: "Miscellaneous")
    var category: String
    
    @Parameter(title: "Is this a recurring subscription?", default: false)
    var isRecurring: Bool
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // --- FIX: Use exact same ModelConfiguration as the Main App to prevent SQLite locks ---
        let schema = Schema([VaultItem.self, VaultCluster.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // Must match the configuration in VaultScanApp
        )
        
        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            throw NSError(domain: "VaultScanError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access database."])
        }
        
        let context = container.mainContext
        
        let newItem = VaultItem(
            title: isRecurring ? "Subscription" : "Digital Receipt",
            vendorName: vendor,
            amount: amount,
            isWarrantyTracked: false
        )
        
        // Find or create the semantic cluster based on what the user told Siri
        let descriptor = FetchDescriptor<VaultCluster>()
        let existingClusters = (try? context.fetch(descriptor)) ?? []
        
        var assignedCluster = existingClusters.first(where: { $0.name.lowercased() == category.lowercased() })
        
        if assignedCluster == nil {
            let newCluster = VaultCluster(name: category.capitalized, systemIcon: "folder.fill")
            context.insert(newCluster)
            assignedCluster = newCluster
        }
        
        // Link the node to the graph edge
        newItem.cluster = assignedCluster
        assignedCluster?.items?.append(newItem)
        
        context.insert(newItem)
        try? context.save()
        
        return .result(
            value: "Success",
            dialog: "I logged $\(amount) for \(vendor) into your Vault."
        )
    }
}

struct VaultShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add a receipt to \(.applicationName)",
                "Track a purchase in \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "creditcard.fill"
        )
    }
}
