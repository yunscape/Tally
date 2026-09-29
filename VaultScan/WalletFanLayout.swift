import SwiftUI

struct WalletFanLayout: View {
    let items: [VaultItem]
    @Binding var selectedItem: VaultItem?
    
    @State private var flippedItemID: UUID?
    
    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isSelected = selectedItem == item
                let isFlipped = flippedItemID == item.id
                
                WalletFlipCard(item: item, isFlipped: isFlipped)
                    .zIndex(isSelected ? 1000 : Double(items.count - index))
                    
                    .offset(y: calculateOffset(index: index, isSelected: isSelected))
                    
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            if selectedItem == item {
                                flippedItemID = isFlipped ? nil : item.id
                            } else {
                                selectedItem = item
                                flippedItemID = nil
                            }
                        }
                    }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, CGFloat(items.count * 75) + 200)
    }
    
    private func calculateOffset(index: Int, isSelected: Bool) -> CGFloat {
        if selectedItem == nil {
            return CGFloat(index * 75)
        } else if isSelected {
            return 10
        } else {
            return CGFloat(index * 75) + 500
        }
    }
}

struct WalletFlipCard: View {
    let item: VaultItem
    let isFlipped: Bool
    
    var body: some View {
        ZStack {
            if isFlipped {
                CardBackView(item: item)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                VaultArtifactCard(item: item)
            }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
    }
}

// MARK: - The Stylized Back of the Card
struct CardBackView: View {
    let item: VaultItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transaction Data").font(.headline).foregroundColor(.secondary)
                Spacer()
                Image(systemName: "barcode.viewfinder").font(.title2).foregroundColor(.primary)
            }
            Divider()
            
            HStack {
                Text("Category")
                Spacer()
                Text(item.cluster?.name ?? "Miscellaneous").fontWeight(.semibold)
            }
            HStack { Text("Date"); Spacer(); Text(item.date, format: .dateTime.month().day().year()) }
            if let serial = item.serialNumber, !serial.isEmpty {
                HStack { Text("Serial"); Spacer(); Text(serial).monospaced() }
            }
            
            Spacer()
            
            Text("VaultScan Encrypted Artifact")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(24)
        .frame(height: 180)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }
}
