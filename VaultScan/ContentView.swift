import SwiftUI
import SwiftData
import PhotosUI
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var context
    
    // --- UPDATED: Querying both the items and the graph clusters ---
    @Query(sort: \VaultItem.date, order: .reverse) private var items: [VaultItem]
    @Query(sort: \VaultCluster.name) private var clusters: [VaultCluster]
    
    @State private var isScanning = false
    @State private var isProcessing = false
    @State private var showAnalytics = false
    @State private var showSettings = false
    @State private var showFilePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedTab = 0
    @State private var selectedItem: VaultItem?
    
    // --- NEW: Active Cluster Selection ---
    @State private var activeClusterFilter: VaultCluster? = nil
    
    // --- Banner State ---
    @State private var showSuccessBanner = false
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("useWalletLayout") private var useWalletLayout = false
    
    // --- Reading the Haptics Preference ---
    @AppStorage("enableHaptics") private var enableHaptics = true
    
    var totalExpenses: Double { items.reduce(0) { $0 + $1.amount } }
    var activeWarranties: Int { items.filter { $0.isWarrantyTracked }.count }
    
    // --- UPDATED: Filtering first by Graph Cluster, then by Tab ---
    var filteredItems: [VaultItem] {
        var baseItems = items
        
        if let activeCluster = activeClusterFilter {
            baseItems = baseItems.filter { $0.cluster == activeCluster }
        }
        
        switch selectedTab {
        case 1: return baseItems.filter { !$0.isWarrantyTracked }
        case 2: return baseItems.filter { $0.isWarrantyTracked }
        default: return baseItems
        }
    }
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                AmbientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            MetricCard(title: "This Month's Expenses", value: String(format: "$%.2f", totalExpenses), subtitleColor: Color.green.opacity(0.8))
                            
                            Button(action: {
                                if enableHaptics { HapticManager.shared.playImpact() }
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { selectedTab = 2 }
                            }) {
                                MetricCard(title: "Active Warranties", value: "\(activeWarranties)", subtitleColor: Color.orange.opacity(0.8))
                            }
                            .buttonStyle(SpringBounceButtonStyle())
                            #if os(macOS)
                            .focusEffectDisabled()
                            #endif
                        }
                        .padding(.horizontal, 20)
                        
                        Picker("", selection: reduceMotion ? $selectedTab : $selectedTab.animation(.snappy)) {
                            Text("All Items").tag(0)
                            Text("Expenses").tag(1)
                            Text("Warranties").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                        .onChange(of: selectedTab) { _, _ in
                            if enableHaptics { HapticManager.shared.playImpact() }
                        }
                        
                        // --- NEW: SMART CLUSTERS HORIZONTAL SCROLL ---
                        if !clusters.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Smart Clusters")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            if enableHaptics { HapticManager.shared.playImpact() }
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                activeClusterFilter = nil
                                            }
                                        }) {
                                            SmartClusterCapsule(title: "All Artifacts", icon: "square.grid.2x2.fill", count: items.count, isSelected: activeClusterFilter == nil)
                                        }
                                        .buttonStyle(SpringBounceButtonStyle())
                                        
                                        ForEach(clusters) { cluster in
                                            Button(action: {
                                                if enableHaptics { HapticManager.shared.playImpact() }
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                    activeClusterFilter = cluster
                                                }
                                            }) {
                                                SmartClusterCapsule(title: cluster.name, icon: cluster.systemIcon, count: cluster.items?.count ?? 0, isSelected: activeClusterFilter == cluster)
                                            }
                                            .buttonStyle(SpringBounceButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Vault")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        
                        // --- THE SNEAK MENU ---
                        #if os(iOS)
                        // Tap = Zero-UI Camera, Long-Press = Picker Menu
                        Menu {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label("Upload Image", systemImage: "photo.on.rectangle")
                            }
                            Button(action: { showFilePicker = true }) {
                                Label("Import PDF", systemImage: "doc.viewfinder.fill")
                            }
                        } label: {
                            Image(systemName: "plus")
                        } primaryAction: {
                            if enableHaptics { HapticManager.shared.playImpact() }
                            isScanning = true
                        }
                        #elseif os(macOS)
                        // Click = Continuity Scanner, Right-Click = Native Mac File Picker
                        Button(action: { /* AppKit Continuity handles the direct click */ }) {
                            Image(systemName: "plus")
                        }
                        .overlay(
                            MacContinuityScannerOverlay { cgImage in
                                processInstantScan(cgImage)
                            }
                        )
                        .contextMenu {
                            Button("Import File (Image or PDF)") { showFilePicker = true }
                        }
                        #endif
                        
                        Button(action: { showAnalytics = true }) { Image(systemName: "chart.bar.xaxis") }
                        Button(action: { showSettings = true }) { Image(systemName: "gear") }
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        } content: {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()
                
                ScrollView {
                    if filteredItems.isEmpty {
                        Text(activeClusterFilter == nil ? "No artifacts found" : "No artifacts in this cluster")
                            .font(.subheadline).foregroundColor(.secondary).padding(.vertical, 40)
                    } else if useWalletLayout {
                        // --- THE NEW 3D SPATIAL WALLET FAN ---
                        WalletFanLayout(items: filteredItems, selectedItem: $selectedItem)
                            .padding(.horizontal, 20)
                    } else {
                        // --- THE CLASSIC HIGH-SPEED LIST ---
                        LazyVStack(spacing: 16) {
                            ForEach(filteredItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    VaultArtifactCard(item: item)
                                }
                                .buttonStyle(SpringBounceButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    if enableHaptics { HapticManager.shared.playImpact() }
                                })
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "All Items" : selectedTab == 1 ? "Expenses" : "Warranties")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        } detail: {
            if let selected = selectedItem {
                ItemDetailView(item: selected)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Select an artifact to view details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $isScanning) {
            DocumentScannerView { cgImage in
                processInstantScan(cgImage)
            }
        }
        #endif
        .sheet(isPresented: $showAnalytics) { AnalyticsView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        
        // --- NATIVE FILE & PHOTO HANDLERS ---
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .image]) { result in
            if case .success(let url) = result {
                if url.pathExtension.lowercased() == "pdf" {
                    parsePDF(at: url)
                } else {
                    parseImageFile(at: url)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newPhotoItem in
            Task {
                guard let data = try? await newPhotoItem?.loadTransferable(type: Data.self) else { return }
                
                #if os(iOS)
                if let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage {
                    processInstantScan(cgImage)
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: data), let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    processInstantScan(cgImage)
                }
                #endif
            }
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView().controlSize(.large)
                        Text("Extracting Data...").font(.headline)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                }
            }
        }
        // --- NEW: Transient Success Banner ---
        .overlay(alignment: .top) {
            if showSuccessBanner {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Artifact Captured")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThickMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 15, y: 8)
                .overlay(Capsule().stroke(Color.primary.opacity(0.05), lineWidth: 1))
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .scale(scale: 0.9)).combined(with: .opacity))
            }
        }
        // --- THE ONBOARDING TRIGGER ---
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { hasCompletedOnboarding = !$0 }
        )) {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
    
    // --- UPDATED: Relational Graph Architecture & Neural Engine Trigger ---
    private func processInstantScan(_ cgImage: CGImage) {
        isProcessing = true
        
        Task {
            let result = await OCRService.shared.processImage(cgImage)
            
            // 1. Process through the Semantic Anchor Engine
            let semanticConcept = VaultIntelligenceEngine.shared.processArtifact(vendor: result.vendor, amount: result.amount, existingClusters: clusters)
            
            await MainActor.run {
                // 2. Find existing cluster or generate a new one
                var assignedCluster = clusters.first(where: { $0.name == semanticConcept })
                
                if assignedCluster == nil {
                    // Create a new cluster node dynamically
                    let newCluster = VaultCluster(name: semanticConcept, systemIcon: "wand.and.stars")
                    context.insert(newCluster)
                    assignedCluster = newCluster
                }
                
                // 3. Create the artifact node
                let newItem = VaultItem(
                    title: "Imported Receipt",
                    vendorName: result.vendor,
                    amount: result.amount,
                    isWarrantyTracked: false
                )
                
                // 4. Form the graph edge (relationship)
                newItem.cluster = assignedCluster
                assignedCluster?.items?.append(newItem)
                
                context.insert(newItem)
                isProcessing = false
                isScanning = false
                selectedItem = newItem
                
                // Trigger the physical feedback and the UI banner
                if enableHaptics { HapticManager.shared.playSuccess() }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showSuccessBanner = true
                }
                
                // Automatically dismiss the banner after 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showSuccessBanner = false
                    }
                }
            }
        }
    }
    
    private func parsePDF(at url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        isProcessing = true
        
        guard let pdfDocument = PDFDocument(url: url),
              let firstPage = pdfDocument.page(at: 0) else {
            url.stopAccessingSecurityScopedResource()
            isProcessing = false
            return
        }
        
        let pageSize = firstPage.bounds(for: .mediaBox).size
        
        #if os(iOS)
        let uiImage = firstPage.thumbnail(of: pageSize, for: .mediaBox)
        if let cgImage = uiImage.cgImage { processInstantScan(cgImage) }
        #elseif os(macOS)
        let nsImage = firstPage.thumbnail(of: pageSize, for: .mediaBox)
        if let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) { processInstantScan(cgImage) }
        #endif
        
        url.stopAccessingSecurityScopedResource()
    }
    
    private func parseImageFile(at url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        isProcessing = true
        
        do {
            let data = try Data(contentsOf: url)
            #if os(iOS)
            if let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage {
                processInstantScan(cgImage)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(data: data), let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                processInstantScan(cgImage)
            }
            #endif
        } catch {
            isProcessing = false
        }
        
        url.stopAccessingSecurityScopedResource()
    }
}

// MARK: - Subcomponents

// --- NEW: Smart Cluster UI Component ---
struct SmartClusterCapsule: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isSelected ? .white : .blue)
                .font(.subheadline)
            
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
            
            Text("\(count)")
                .font(.caption2.bold())
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isSelected ? Color.blue : Color.clear)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(isSelected ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1))
    }
}

struct VaultArtifactCard: View {
    let item: VaultItem
    
    var amountFont: Font {
        if item.amount >= 1000 {
            return .system(size: 32, weight: .heavy, design: .rounded)
        } else if item.amount >= 100 {
            return .system(size: 24, weight: .bold, design: .rounded)
        } else {
            return .system(size: 18, weight: .semibold, design: .rounded)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.vendorName).font(.headline).foregroundColor(.primary)
                    Text(item.date, format: .dateTime.month().day().year()).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "$%.2f", item.amount))
                    .font(amountFont)
                    .monospacedDigit()
                    .foregroundColor(.primary)
            }
            
            HStack {
                // --- UPDATED: Now accesses the new relational graph cluster ---
                Text(item.cluster?.name ?? "Miscellaneous")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Capsule())
                Spacer()
                if item.isWarrantyTracked {
                    Image(systemName: "shield.checkmark.fill").foregroundColor(.orange.opacity(0.8))
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.vaultSecondaryBackground, .vaultBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitleColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).fontWeight(.medium).foregroundColor(.secondary)
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18)
        .background(.ultraThinMaterial).cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 12, y: 6)
    }
}

struct AmbientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()
            GeometryReader { proxy in
                Circle().fill(Color.blue.opacity(colorScheme == .dark ? 0.12 : 0.06)).blur(radius: 90).offset(x: -proxy.size.width * 0.1, y: -proxy.size.height * 0.1)
                Circle().fill(Color.purple.opacity(colorScheme == .dark ? 0.12 : 0.06)).blur(radius: 90).offset(x: proxy.size.width * 0.4, y: proxy.size.height * 0.3)
            }
        }.ignoresSafeArea()
    }
}

struct SpringBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension Color {
    static var vaultBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    static var vaultSecondaryBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
