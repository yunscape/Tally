import SwiftUI
import LocalAuthentication
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("appTheme") private var appTheme = 0
    @AppStorage("requireFaceID") private var requireFaceID = false
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("useWalletLayout") private var useWalletLayout = false
    @AppStorage("enableCloudSync") private var enableCloudSync = false
    
    @State private var showBiometricAlert = false
    @State private var showPlaceholderAlert = false
    @State private var pendingSyncState = false
    @State private var showSyncExplanation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Circle().fill(Color.blue.opacity(0.15)).frame(width: 60, height: 60)
                            .overlay(Text("DK").font(.title2.bold()).foregroundColor(.blue))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dawar Diganta J Kashyap").font(.headline)
                            Text("Local Device Account • Not Syncing").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Appearance") {
                    Picker(selection: $appTheme, label: Label("Theme", systemImage: "paintbrush.fill")) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    
                    // Fixed deprecated binding animation by observing it on the Section below
                    Toggle(isOn: $useWalletLayout) {
                        Label("3D Wallet Layout", systemImage: "square.stack.3d.up.fill")
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: useWalletLayout)
                
                Section("Security & Privacy") {
                    Toggle(isOn: Binding(
                        get: { requireFaceID },
                        set: { newValue in toggleBiometrics(newValue) }
                    )) {
                        Label("Require Face ID / Touch ID", systemImage: "faceid")
                    }
                    
                    Toggle(isOn: Binding(
                        get: { enableCloudSync },
                        set: { newValue in
                            if newValue {
                                pendingSyncState = true
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    showSyncExplanation = true
                                }
                            } else {
                                enableCloudSync = false
                            }
                        }
                    )) {
                        Label("iCloud Device Sync", systemImage: "icloud.and.arrow.up.fill")
                    }
                    
                    NavigationLink(destination: PrivacyAndStorageView()) {
                        Label("Privacy & Local Storage", systemImage: "lock.shield.fill")
                    }
                }
                
                Section(header: Text("Accessibility"), footer: Text("These settings adapt VaultScan's interface independently of your global device settings.")) {
                    Toggle(isOn: $enableHaptics) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }
                    Toggle(isOn: $reduceMotion) {
                        Label("Reduce App Motion", systemImage: "wind.snow")
                    }
                }
                
                Section(
                    header: Text("Open Source"),
                    footer: Text("VaultScan is open source. Contribute, inspect the codebase, or report issues on GitHub.")
                ) {
                    Button(action: {
                        showPlaceholderAlert = true
                    }) {
                        HStack {
                            Label("GitHub Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(macOS)
            .formStyle(.grouped)
            .frame(width: 450, height: 500)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    #if os(macOS)
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                    }
                    #else
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                    #endif
                }
            }
            .alert("Biometrics Unavailable", isPresented: $showBiometricAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This device does not have Face ID or Touch ID configured. Please set it up in your iOS Settings first.")
            }
            .alert("GitHub Repository", isPresented: $showPlaceholderAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The codebase is currently local. The GitHub repository link will become active once the project files are pushed online.")
            }
            .preferredColorScheme(appTheme == 1 ? .light : appTheme == 2 ? .dark : nil)
            .onChange(of: appTheme) { _, _ in
                triggerSmoothTransition()
            }
            .overlay {
                if showSyncExplanation {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { showSyncExplanation = false }
                            }
                        
                        VStack(spacing: 24) {
                            // The Hero Icon
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.15)).frame(width: 80, height: 80)
                                Image(systemName: "icloud.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Enable iCloud Sync?")
                                    .font(.title2.bold())
                                Text("VaultScan will securely sync your receipts across your Mac, iPad, and iPhone using your personal iCloud quota. We never see your data.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        enableCloudSync = true
                                        showSyncExplanation = false
                                    }
                                }) {
                                    Text("Turn On Sync")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        showSyncExplanation = false
                                    }
                                }) {
                                    Text("Keep Local Only")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.primary.opacity(0.08))
                                        .foregroundColor(.primary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                        .padding(.horizontal, 30)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                    .zIndex(1)
                }
            }
        }
    }
    
    private func toggleBiometrics(_ isOn: Bool) {
        if isOn {
            let context = LAContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                requireFaceID = true
            } else {
                showBiometricAlert = true
                requireFaceID = false
            }
        } else {
            requireFaceID = false
        }
    }
    
    private func triggerSmoothTransition() {
        #if os(macOS)
        if let window = NSApplication.shared.windows.first {
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.add(transition, forKey: "ThemeCrossfade")
        }
        #elseif os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
        #endif
    }
}
