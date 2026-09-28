import SwiftUI
import SwiftData
import PassKit

struct ItemDetailView: View {
    @Bindable var item: VaultItem
    
    // Dynamically fetch available semantic clusters for the Category Picker
    @Query(sort: \VaultCluster.name) private var clusters: [VaultCluster]
    
    // --- Wallet Integration States ---
    @State private var isGeneratingPass = false
    @State private var generatedPass: PKPass?
    @State private var showPassSheet = false
    
    var body: some View {
        Form {
            Section(header: Text("Transaction Details")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title").font(.caption).foregroundColor(.secondary)
                    TextField("Title", text: $item.title)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vendor").font(.caption).foregroundColor(.secondary)
                    TextField("Vendor (e.g., Apple, Maxbhi.com)", text: $item.vendorName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Amount ($)").font(.caption).foregroundColor(.secondary)
                    TextField("Amount", value: $item.amount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                DatePicker("Date", selection: $item.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                // Safely handles the new Graph Edge relationship
                Picker("Category", selection: $item.cluster) {
                    Text("Miscellaneous").tag(nil as VaultCluster?)
                    ForEach(clusters) { cluster in
                        Text(cluster.name).tag(cluster as VaultCluster?)
                    }
                }
                
                Toggle("Tax Deductible", isOn: $item.isDeductible)
            }
            
            Section(
                header: Text("Warranty & Support"),
                footer: Text("Set expiration dates to track return windows for replacement components.")
            ) {
                Toggle("Track Warranty", isOn: $item.isWarrantyTracked)
                
                if item.isWarrantyTracked {
                    DatePicker("Expiry Date", selection: Binding(
                        get: { item.expiryDate ?? Date().addingTimeInterval(31536000) },
                        set: { item.expiryDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Serial Number / Order ID").font(.caption).foregroundColor(.secondary)
                        TextField("Enter serial number or order ID", text: Binding(
                            get: { item.serialNumber ?? "" },
                            set: { item.serialNumber = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                }
            }
            .animation(.default, value: item.isWarrantyTracked)
            
            // --- NEW: THE APPLE WALLET SECTION ---
            #if os(iOS)
            Section(
                header: Text("Apple Wallet Integration"),
                footer: Text("Export this artifact to your system Wallet for quick access to warranty barcodes and receipt details.")
            ) {
                if isGeneratingPass {
                    HStack {
                        Spacer()
                        ProgressView("Cryptographically signing pass...")
                            .controlSize(.regular)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    HStack {
                        Spacer()
                        // The Native Apple Button
                        AddToWalletButton {
                            generateAndShowPass()
                        }
                        .frame(width: 140, height: 40)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    // Hides the standard form row background so the button floats cleanly
                    .listRowBackground(Color.clear)
                }
            }
            #endif
        }
        .navigationTitle("Edit Item")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        // SUMMONS THE WALLET SHEET
        .sheet(isPresented: $showPassSheet) {
            if let pass = generatedPass {
                AddPassView(pass: pass)
            }
        }
        #endif
        #if os(macOS)
        .formStyle(.grouped)
        .padding()
        #endif
    }
    
    // MARK: - Pass Generation Logic
    private func generateAndShowPass() {
        isGeneratingPass = true
        
        Task {
            // Reaches out to the backend simulation service
            if let pass = await WalletPassService.fetchSignedPass(for: item) {
                await MainActor.run {
                    generatedPass = pass
                    isGeneratingPass = false
                    showPassSheet = true
                }
            } else {
                // Fails gracefully if the backend isn't connected yet
                await MainActor.run {
                    isGeneratingPass = false
                    print("Backend connection required for Pass signing.")
                }
            }
        }
    }
}
