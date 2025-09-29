import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var metrics: ConsoleMetricsService
    @EnvironmentObject private var iapService: IAPService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var selectedTab = 0
    
    var body: some View {
        let toastBinding = Binding<String?>(
            get: { dependencies.toastMessage },
            set: { dependencies.toastMessage = $0 }
        )
        
        TabView(selection: $selectedTab) {
            // SOPs Tab
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        router.destination(for: route)
                    }
            }
            .tabItem {
                Image(systemName: "doc.text")
                Text("SOPs")
            }
            .tag(0)
            
            // Templates Tab
            NavigationStack {
                TemplatesView()
            }
            .tabItem {
                Image(systemName: "doc.on.doc")
                Text("Templates")
            }
            .tag(1)
            
            // Record Tab
            NavigationStack {
                RecordView()
            }
            .tabItem {
                Image(systemName: "mic.circle")
                Text("Record")
            }
            .tag(2)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            .tag(3)
        }
        .toast(message: toastBinding)
        .transaction { transaction in
            if reduceMotion {
                transaction.disablesAnimations = true
            }
        }
        .onReceive(iapService.$statusMessage.compactMap { $0 }) { message in
            dependencies.presentToast(message)
            iapService.statusMessage = nil
        }
        .task {
            SeedData.ensureDefaults(context: context)
            metrics.track(event: .appLaunch)
            await iapService.refreshSubscriptions()
            handleUITestNavigation()
        }
        .onReceive(iapService.$entitlements) { entitlements in
            let isPro = entitlements.contains(.proUnlimited)
            try? dependencies.quotaService.setProStatus(isActive: isPro, using: context)
        }
    }
}

// MARK: - Templates View
struct TemplatesView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @Query(sort: \Template.name) private var templates: [Template]
    @State private var searchText = ""
    @State private var templateService: TemplateService?
    @State private var showingCreateTemplate = false
    
    var body: some View {
        VStack {
            if templates.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredTemplates) { template in
                        TemplateRowView(template: template, templateService: templateService)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText)
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Template") {
                    showingCreateTemplate = true
                }
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView(templateService: templateService)
        }
        .task {
            templateService = DefaultTemplateService(context: context, metrics: dependencies.metrics)
            await loadDefaultTemplates()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Templates")
                .font(.title2)
                .fontWeight(.medium)
            Text("Create templates to quickly start new SOPs")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var filteredTemplates: [Template] {
        guard !searchText.isEmpty else { return templates }
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchText) ||
            template.description?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    private func loadDefaultTemplates() async {
        do {
            _ = try await templateService?.loadDefaultTemplates()
        } catch {
            print("Failed to load default templates: \(error)")
        }
    }
}

// MARK: - Template Row View
struct TemplateRowView: View {
    let template: Template
    let templateService: TemplateService?
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @Environment(\.modelContext) private var context
    @State private var isDuplicating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                Spacer()
                Button("Duplicate") {
                    Task {
                        await duplicateTemplate()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isDuplicating)
            }
            
            if let description = template.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if template.sample {
                    Text("Sample Template")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if isDuplicating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func duplicateTemplate() async {
        guard let templateService = templateService else { return }
        
        isDuplicating = true
        defer { isDuplicating = false }
        
        do {
            let newSOP = try await templateService.duplicateTemplate(template)
            dependencies.presentToast("Template duplicated successfully")
            
            // Navigate to the new SOP
            dependencies.router.push(.edit(sopID: newSOP.persistentModelID))
        } catch {
            dependencies.presentToast("Failed to duplicate template: \(error.localizedDescription)")
        }
    }
}

// MARK: - Create Template View
struct CreateTemplateView: View {
    let templateService: TemplateService?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @Query(sort: \SOP.title) private var sops: [SOP]
    @State private var selectedSOP: SOP?
    
    var body: some View {
        NavigationView {
            VStack {
                if sops.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sops) { sop in
                            SOPTemplateRowView(sop: sop, isSelected: selectedSOP?.id == sop.id) {
                                selectedSOP = sop
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createTemplate()
                        }
                    }
                    .disabled(selectedSOP == nil)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No SOPs Available")
                .font(.title2)
                .fontWeight(.medium)
            Text("Create a SOP first to use as a template")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func createTemplate() async {
        guard let selectedSOP = selectedSOP, let templateService = templateService else { return }
        
        do {
            _ = try await templateService.createTemplate(from: selectedSOP)
            dependencies.presentToast("Template created successfully")
            dismiss()
        } catch {
            dependencies.presentToast("Failed to create template: \(error.localizedDescription)")
        }
    }
}

// MARK: - SOP Template Row View
struct SOPTemplateRowView: View {
    let sop: SOP
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sop.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let summary = sop.summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("\(sop.steps.count) steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Record View
struct RecordView: View {
    @EnvironmentObject private var dependencies: AppDependencyContainer
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("Quick Voice Capture")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Record your voice and convert it to a draft SOP")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button {
                    dependencies.metrics.track(event: .captureStarted, properties: ["mode": "voice"])
                    dependencies.router.push(.capture)
                } label: {
                    Label("Start Recording", systemImage: "mic.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .a11y(
                    id: "record.start",
                    label: "Start voice recording",
                    traits: .button
                )
                
                Button {
                    dependencies.metrics.track(event: .captureStarted, properties: ["mode": "text"])
                    dependencies.router.push(.paste)
                } label: {
                    Label("Type Instead", systemImage: "doc.on.clipboard")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
                .a11y(
                    id: "record.text",
                    label: "Type text instead of recording",
                    traits: .button
                )
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Record")
    }
}

// MARK: - Extensions
private extension MainTabView {
    func handleUITestNavigation() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--ui-testing") else { return }

        if arguments.contains("--ui-show-paywall") {
            dependencies.router.push(.paywall(trigger: .quota))
        }

        if arguments.contains("--ui-show-export") {
            let sop = ensureSampleSOP()
            dependencies.router.push(.export(sopID: sop.persistentModelID))
        }
    }

    func ensureSampleSOP() -> SOP {
        if let existing = try? context.fetch(FetchDescriptor<SOP>(predicate: #Predicate { $0.title == "UI Test Sample" }, fetchLimit: 1)).first {
            return existing
        }

        let steps = [
            SOPStep(order: 1, title: "Gather inputs"),
            SOPStep(order: 2, title: "Review with team"),
            SOPStep(order: 3, title: "Publish and share")
        ]

        let sop = SOP(
            title: "UI Test Sample",
            summary: "Sample SOP used in UI automation.",
            tags: ["test"],
            steps: steps,
            sourceRaw: "UI Test Sample",
            status: .draft
        )
        context.insert(sop)
        try? context.save()
        return sop
    }
}
