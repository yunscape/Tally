import Foundation
import SwiftData

@Model
final class VaultItem {
    @Attribute(.unique) var id: UUID = UUID()
    
    var title: String = ""
    var vendorName: String = ""
    var amount: Double = 0.0
    var date: Date = Date()
    
    // Feature: Tax Deductible & Subscriptions
    var isDeductible: Bool = false
    var isRecurring: Bool = false
    var billingCycle: String? = nil
    
    // Feature: Warranties & Digital Integration
    var isWarrantyTracked: Bool = false
    var expiryDate: Date? = nil
    var serialNumber: String? = nil
    var importedFromWallet: Bool = false
    var sourceApp: String? = nil
    
    // --- THE GRAPH EDGE ---
    // Links this specific receipt to a dynamically generated cluster
    @Relationship(inverse: \VaultCluster.items)
    var cluster: VaultCluster?
    
    init(
        title: String = "Imported Receipt",
        vendorName: String = "",
        amount: Double = 0.0,
        date: Date = Date(),
        isDeductible: Bool = false,
        isRecurring: Bool = false,
        billingCycle: String? = nil,
        isWarrantyTracked: Bool = false,
        expiryDate: Date? = nil,
        serialNumber: String? = nil,
        importedFromWallet: Bool = false,
        sourceApp: String? = nil
    ) {
        self.title = title
        self.vendorName = vendorName
        self.amount = amount
        self.date = date
        self.isDeductible = isDeductible
        self.isRecurring = isRecurring
        self.billingCycle = billingCycle
        self.isWarrantyTracked = isWarrantyTracked
        self.expiryDate = expiryDate
        self.serialNumber = serialNumber
        self.importedFromWallet = importedFromWallet
        self.sourceApp = sourceApp
    }
}

@Model
final class VaultCluster {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var systemIcon: String = "folder.fill"
    
    // The interconnected nodes (receipts) in this semantic cluster
    var items: [VaultItem]? = []
    
    init(name: String, systemIcon: String = "folder.fill") {
        self.name = name
        self.systemIcon = systemIcon
    }
}
