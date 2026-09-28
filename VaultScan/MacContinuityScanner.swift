import SwiftUI

#if os(macOS)
import AppKit

// This creates an invisible Mac button that sits on top of our SwiftUI button
struct MacContinuityScannerOverlay: NSViewRepresentable {
    var onScanComplete: (CGImage) -> Void
    
    func makeNSView(context: Context) -> ContinuityButton {
        let button = ContinuityButton()
        button.onScanComplete = onScanComplete
        return button
    }
    
    func updateNSView(_ nsView: ContinuityButton, context: Context) {}
}

class ContinuityButton: NSButton, NSServicesMenuRequestor {
    var onScanComplete: ((CGImage) -> Void)?
    
    init() {
        super.init(frame: .zero)
        self.isTransparent = true // Makes the AppKit button invisible so we only see our custom UI
        self.target = self
        self.action = #selector(triggerContinuityMenu)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    @objc func triggerContinuityMenu() {
        self.window?.makeFirstResponder(self)
        
        // This is the native Apple API that opens the "Scan with iPhone" context menu
        NSApp.sendAction(Selector(("importFromDevice:")), to: nil, from: self)
    }
    
    // FIX 1: acceptsFirstResponder is a property in modern Swift, not a function
    override var acceptsFirstResponder: Bool { return true }
    
    // Tells the Mac we are ready to receive an image from the iPhone
    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        if returnType == .tiff || returnType == .png {
            return self
        }
        return super.validRequestor(forSendType: sendType, returnType: returnType)
    }
    
    // FIX 2: Removed 'override' because this is fulfilling a protocol
    func readSelection(from pboard: NSPasteboard) -> Bool {
        guard let images = pboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
              let firstImage = images.first,
              let cgImage = firstImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }
        
        // Pass it back to our AI Neural Engine
        onScanComplete?(cgImage)
        return true
    }
}
#endif
