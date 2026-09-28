import SwiftUI

// This checks if we are running on an iPhone/iPad
#if os(iOS)
import UIKit
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onScanComplete: ((CGImage) -> Void)
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        // When the user taps "Save" on the camera screen
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                // Grab the perfectly cropped first page
                let image = scan.imageOfPage(at: 0)
                if let cgImage = image.cgImage {
                    parent.onScanComplete(cgImage)
                }
            }
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
    }
}

#else
// This is the fallback view for your Mac since it doesn't have a rear document camera
struct DocumentScannerView: View {
    @Environment(\.dismiss) private var dismiss
    var onScanComplete: ((CGImage) -> Void)
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "desktopcomputer.trianglebadge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Camera Scanner requires iOS.")
                .font(.headline)
            Text("To test the native document scanner, run this app on an iPhone Simulator instead of 'My Mac'.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}
#endif
