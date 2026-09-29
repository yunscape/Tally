import SwiftUI

struct VaultRowView: View {
    let item: VaultItem
    
    var categoryIcon: String {
        let clusterName = item.cluster?.name ?? "Miscellaneous"
        
        switch clusterName {
        case "Dining": return "fork.knife"
        case "Software": return "macwindow"
        case "Travel": return "airplane"
        case "Utilities": return "bolt.fill"
        case "Supplies": return "shippingbox.fill"
        default: return "creditcard.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 48, height: 48)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.vendorName)
                    .font(.system(.headline, design: .rounded))
                
                HStack(spacing: 6) {
                    Text(item.cluster?.name ?? "Miscellaneous")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    
                    Text(item.date, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", item.amount))
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                
                if item.isDeductible {
                    Text("Deductible")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.green.opacity(0.7))
                } else if item.isWarrantyTracked, let expiry = item.expiryDate {
                    let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
                    
                    Text("\(daysLeft)d left")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange.opacity(0.8))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 6)
    }
}
