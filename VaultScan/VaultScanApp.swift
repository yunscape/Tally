import SwiftUI
import SwiftData
import LocalAuthentication

@main
struct VaultScanApp: App {
    // Moving the theme here ensures it applies globally and fixes Sheet layout bugs
    @AppStorage("appTheme") private var appTheme = 0
    @AppStorage("requireFaceID") private var requireFaceID = false
    
    @State private var isUnlocked = false
    
    // --- CloudKit-Compliant Container Initialization ---
    var sharedModelContainer: ModelContainer = {
        // Registering both VaultItem and VaultCluster for the Graph Architecture
        let schema = Schema([VaultItem.self, VaultCluster.self])
        
        // CloudKit requires the database to be stored on disk, not just in memory
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // Explicitly tells SwiftData to use iCloud
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                
                // The Native App Lock Overlay
                if requireFaceID && !isUnlocked {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Vault is Locked")
                            .font(.title2.bold())
                        
                        Button("Unlock with Biometrics") {
                            authenticate()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial) // Liquid Glass Lock Screen
                    .ignoresSafeArea()
                }
            }
            .preferredColorScheme(appTheme == 1 ? .light : appTheme == 2 ? .dark : nil)
            .onAppear {
                if requireFaceID { authenticate() }
            }
        }
        // Uses the configured CloudKit container instead of the default
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Real Face ID / Touch ID Engine
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your secure vault") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    }
                }
            }
        } else {
            // Fallback if device has no Face ID set up
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Enter device passcode to unlock") { success, _ in
                DispatchQueue.main.async {
                    if success { self.isUnlocked = true }
                }
            }
        }
    }
}
