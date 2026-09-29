import SwiftUI
import SwiftData
import LocalAuthentication

@main
struct VaultScanApp: App {
    @AppStorage("appTheme") private var appTheme = 0
    @AppStorage("requireFaceID") private var requireFaceID = false
    
    @State private var isUnlocked = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([VaultItem.self, VaultCluster.self, VaultProject.self])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
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
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                }
            }
            .preferredColorScheme(appTheme == 1 ? .light : appTheme == 2 ? .dark : nil)
            .onAppear {
                if requireFaceID { authenticate() }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
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
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Enter device passcode to unlock") { success, _ in
                DispatchQueue.main.async {
                    if success { self.isUnlocked = true }
                }
            }
        }
    }
}
