import SwiftUI

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
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
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
