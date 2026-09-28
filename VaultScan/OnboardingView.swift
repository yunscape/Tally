import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            AmbientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Skip Bar
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage = 2
                            }
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(24)
                    } else {
                        // Empty spacer to balance the layout on the final page
                        Color.clear.frame(height: 60)
                    }
                }
                
                // Paging View Content
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        iconName: "square.stack.3d.up.fill",
                        iconColor: .blue,
                        title: "Your Expenses,\nReimagined.",
                        subtitle: "Step away from boring spreadsheets. VaultScan transforms your receipts into physical, spatial artifacts with dynamic typographic weight."
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        iconName: "camera.viewfinder",
                        iconColor: .purple,
                        title: "Instant Capture.\nZero Effort.",
                        subtitle: "Snap a receipt with your camera or import files. Our hybrid Neural Engine instantly categorizes your purchases automatically."
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        iconName: "lock.shield.fill",
                        iconColor: .green,
                        title: "Your Data\nStays Yours.",
                        subtitle: "Fully encrypted and stored locally on-device. Backed by biometric security. Your financial footprint never leaves your ecosystem."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                // Bottom Action Button
                VStack(spacing: 16) {
                    Button(action: {
                        if currentPage < 2 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                hasCompletedOnboarding = true
                            }
                        }
                    }) {
                        Text(currentPage == 2 ? "Get Started" : "Continue")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 10, y: 5)
                    }
                    .buttonStyle(SpringBounceButtonStyle())
                }
                .padding(24)
            }
        }
    }
}

// MARK: - Individual Page Layout
struct OnboardingPage: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Glowing Symbol Card
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)
                
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 15, y: 8)
                
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundColor(iconColor)
            }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
            Spacer()
        }
    }
}
