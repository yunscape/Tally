import SwiftUI

#if os(macOS)
import AppKit

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
        self.isTransparent = true
        self.target = self
        self.action = #selector(triggerContinuityMenu)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func triggerContinuityMenu() {
        self.window?.makeFirstResponder(self)
        
        NSApp.sendAction(Selector(("importFromDevice:")), to: nil, from: self)
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        if returnType == .tiff || returnType == .png {
            return self
        }
        return super.validRequestor(forSendType: sendType, returnType: returnType)
    }
    
    func readSelection(from pboard: NSPasteboard) -> Bool {
        guard let images = pboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
              let firstImage = images.first,
              let cgImage = firstImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }
        
        onScanComplete?(cgImage)
        return true
    }
}
#endif
