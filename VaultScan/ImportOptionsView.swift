import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PhotosUI
import PDFKit

struct ImportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @AppStorage("appTheme") private var appTheme = 0
    
    @State private var showFilePicker = false
    @State private var showScanner = false
    @State private var isProcessing = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 24) {
                    
                    // --- DYNAMIC SCANNER BUTTON ---
                    #if os(iOS)
                    ImportButton(title: "Scan Receipt", icon: "camera.viewfinder", color: .blue) {
                        showScanner = true
                    }
                    #elseif os(macOS)
                    ImportButton(title: "Scan with iPhone", icon: "iphone.and.arrow.forward", color: .blue) {
                        // The click is intercepted by the invisible overlay below
                    }
                    .overlay(
                        MacContinuityScannerOverlay { cgImage in
                            processScannedImage(cgImage)
                        }
                    )
                    #endif
                    // ------------------------------
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .frame(width: 40)
                            Text("Upload Image")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    
                    ImportButton(title: "Import PDF", icon: "doc.viewfinder.fill", color: .orange) {
                        showFilePicker = true
                    }
                }
                .padding(32)
                
                if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Parsing with Apple Vision...")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(30)
                    .background(.regularMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                }
            }
            .navigationTitle("Add to Vault")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Only compiles the iOS native scanner on an iPhone
            #if os(iOS)
            .sheet(isPresented: $showScanner) {
                DocumentScannerView { cgImage in
                    processScannedImage(cgImage)
                }
            }
            #endif
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf]) { result in
                if case .success(let url) = result {
                    parsePDF(at: url)
                }
            }
            .onChange(of: selectedPhoto) { _, newPhotoItem in
                Task {
                    guard let data = try? await newPhotoItem?.loadTransferable(type: Data.self) else { return }
                    
                    #if os(iOS)
                    if let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage {
                        processScannedImage(cgImage)
                    }
                    #elseif os(macOS)
                    if let nsImage = NSImage(data: data), let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                        processScannedImage(cgImage)
                    }
                    #endif
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(appTheme == 1 ? .light : appTheme == 2 ? .dark : nil)
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
        if let cgImage = uiImage.cgImage { processScannedImage(cgImage) }
        #elseif os(macOS)
        let nsImage = firstPage.thumbnail(of: pageSize, for: .mediaBox)
        if let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) { processScannedImage(cgImage) }
        #endif
        
        url.stopAccessingSecurityScopedResource()
    }
    
    private func processScannedImage(_ cgImage: CGImage) {
        isProcessing = true
        Task {
            let result = await OCRService.shared.processImage(cgImage)
            
            let newItem = VaultItem(
                title: "Imported Receipt",
                vendorName: result.vendor,
                amount: result.amount,
                category: "Hardware",
                isWarrantyTracked: false
            )
            context.insert(newItem)
            
            isProcessing = false
            dismiss()
        }
    }
}

struct ImportButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 40)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
