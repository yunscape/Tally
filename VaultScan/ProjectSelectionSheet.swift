import SwiftUI
import SwiftData

struct ProjectSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \VaultProject.name) private var allProjects: [VaultProject]
    
    @Bindable var item: VaultItem
    
    var body: some View {
        NavigationStack {
            List {
                if allProjects.isEmpty {
                    Text("No active budgets. Create one from the Dashboard first.")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(allProjects) { project in
                        let isSelected = item.projects?.contains(project) ?? false
                        
                        Button(action: {
                            toggleAssignment(for: project)
                        }) {
                            HStack {
                                Label(project.name, systemImage: project.systemIcon)
                                    .foregroundColor(.primary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Link to Budget")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        #if os(macOS)
        .frame(width: 350, height: 400)
        #endif
    }
    
    private func toggleAssignment(for project: VaultProject) {
        if item.projects == nil { item.projects = [] }
        
        if let index = item.projects?.firstIndex(of: project) {
            item.projects?.remove(at: index)
        } else {
            item.projects?.append(project)
        }
    }
}
