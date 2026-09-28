import SwiftUI

struct WalletFanLayout: View {
    let items: [VaultItem]
    @Binding var selectedItem: VaultItem?
    
    @State private var flippedItemID: UUID? // Tracks which card is currently showing its back
    
    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isSelected = selectedItem == item
                let isFlipped = flippedItemID == item.id
                
                WalletFlipCard(item: item, isFlipped: isFlipped)
                    // 1. Z-INDEX: Ensures the selected card always jumps to the very front
                    .zIndex(isSelected ? 1000 : Double(items.count - index))
                    
                    // 2. THE FAN MATH: Calculates where the card sits on the screen
                    .offset(y: calculateOffset(index: index, isSelected: isSelected))
                    
                    // 3. THE INTERACTION: Tap to select, tap again to flip
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            if selectedItem == item {
                                // If already selected, flip it over!
                                flippedItemID = isFlipped ? nil : item.id
                            } else {
                                // Bring to focus, reset flip state
                                selectedItem = item
                                flippedItemID = nil
                            }
                        }
                    }
            }
        }
        .padding(.top, 20)
        // Dynamically size the container based on how many cards are fanned out
        .padding(.bottom, CGFloat(items.count * 75) + 200)
    }
    
    private func calculateOffset(index: Int, isSelected: Bool) -> CGFloat {
        if selectedItem == nil {
            // State 1: Resting Fan (Cards peek out 75 points below each other)
            return CGFloat(index * 75)
        } else if isSelected {
            // State 2: Active Focus (Selected card jumps to the top)
            return 10
        } else {
            // State 3: Pushed Away (Unselected cards slide off to the bottom)
            return CGFloat(index * 75) + 500
        }
    }
}

// MARK: - The 3D Flip Card Component
struct WalletFlipCard: View {
    let item: VaultItem
    let isFlipped: Bool
    
    var body: some View {
        ZStack {
            if isFlipped {
                // THE BACK: The detailed receipt data
                CardBackView(item: item)
                    // Pre-flip this view so it looks correct when the whole container rotates
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // THE FRONT: Your existing beautiful artifact
                VaultArtifactCard(item: item)
            }
        }
        // The master 3D rotation modifier
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5 // Gives it that realistic 3D depth distortion
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
            
            HStack { Text("Category"); Spacer(); Text(item.category).fontWeight(.semibold) }
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
        .frame(height: 180) // Approximates the height of the front card
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }
}
