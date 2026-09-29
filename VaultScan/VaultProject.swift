import Foundation
import SwiftData
import SwiftUI

@Model
final class VaultProject {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var budgetLimit: Double = 0.0
    var startDate: Date = Date()
    var systemIcon: String = "briefcase.fill"
    var items: [VaultItem]? = []
    var totalSpent: Double {
        return items?.reduce(0.0) { $0 + $1.amount } ?? 0.0
    }
    
    var budgetProgress: Double {
        guard budgetLimit > 0 else { return 0.0 }
        return min(totalSpent / budgetLimit, 1.0)
    }
    
    init(name: String, budgetLimit: Double = 0.0, startDate: Date = Date(), systemIcon: String = "briefcase.fill") {
        self.name = name
        self.budgetLimit = budgetLimit
        self.startDate = startDate
        self.systemIcon = systemIcon
    }
}
