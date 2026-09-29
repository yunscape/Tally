import SwiftUI
import SwiftData

struct ProjectDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VaultProject.startDate, order: .reverse) private var projects: [VaultProject]
    
    @State private var showingNewProject = false
    @State private var newProjectName = ""
    @State private var newProjectBudget: Double = 15000.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if projects.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Active Budgets")
                            .font(.title3.bold())
                        Text("Group your receipts to track spending for specific events, travel, or hardware builds.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(projects) { project in
                            ProjectCard(project: project)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(project)
                                    } label: {
                                        Label("Delete Budget", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Contextual Budgets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NavigationStack {
                    Form {
                        Section("Project Details") {
                            TextField("e.g., Simulation Rig Build or Silchar Trip", text: $newProjectName)
                            
                            HStack {
                                Text("Budget Limit (₹)")
                                Spacer()
                                TextField("Amount", value: $newProjectBudget, format: .number)
                                    #if os(iOS)
                                    .keyboardType(.decimalPad)
                                    #endif
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .navigationTitle("New Budget")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingNewProject = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                let project = VaultProject(
                                    name: newProjectName.isEmpty ? "New Event" : newProjectName,
                                    budgetLimit: newProjectBudget
                                )
                                context.insert(project)
                                newProjectName = ""
                                showingNewProject = false
                            }
                        }
                    }
                }
                #if os(macOS)
                .frame(width: 400, height: 300)
                #endif
            }
        }
    }
}

// MARK: - Subcomponents
struct ProjectCard: View {
    let project: VaultProject
    
    var gaugeColor: Color {
        let progress = project.budgetProgress
        if progress < 0.6 { return .green }
        if progress < 0.9 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label(project.name, systemImage: project.systemIcon)
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Text("\(project.items?.count ?? 0) items")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Capsule())
            }
            
            Gauge(
                value: project.budgetProgress,
                in: 0.0...1.0,
                label: {
                    Text("Budget Progress")
                },
                currentValueLabel: {
                    Text(String(format: "₹%.0f", project.totalSpent))
                        .monospacedDigit()
                },
                minimumValueLabel: {
                    Text("₹0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                },
                maximumValueLabel: {
                    Text(String(format: "₹%.0f", project.budgetLimit))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            )
            .gaugeStyle(.accessoryLinear)
            .labelsHidden()
            .tint(gaugeColor)
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.vaultSecondaryBackground, .vaultBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 15, y: 8)
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}
