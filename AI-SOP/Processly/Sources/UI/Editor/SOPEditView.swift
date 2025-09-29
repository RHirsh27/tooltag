import SwiftUI
import UIKit
import SwiftData

struct SOPEditView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var dependencies: AppDependencyContainer
    let sopID: PersistentIdentifier
    @State private var sop: SOP?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let sop {
                editor(for: sop)
            } else {
                ProgressView()
                    .task(load)
            }
        }
        .navigationTitle(L10n.Edit.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.Finalize.button) {
                    dependencies.router.push(.finalize(sopID: sopID))
                }
            }
        }
    }

    private func editor(for sop: SOP) -> some View {
        @Bindable var binding = sop
        return Form {
            Section(L10n.Edit.sectionTitle) {
                TextField(L10n.Edit.sectionTitle, text: $binding.title)
                    .onChange(of: binding.title) { _ in updateTimestamp() }
            }
            Section(L10n.Edit.sectionSummary) {
                TextEditor(text: $binding.summary)
                    .frame(minHeight: 120)
                    .accessibilityLabel(L10n.Edit.sectionSummary)
                    .onChange(of: binding.summary) { _ in updateTimestamp() }
            }
            Section(L10n.Edit.sectionTools) {
                TagEditor(tags: $binding.tags)
            }
            Section(L10n.Edit.sectionSteps) {
                ForEach(Array(binding.steps.enumerated()), id: \.element.id) { index, _ in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            // Drag handle
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            // Step number
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            
                            Spacer()
                            
                            // Delete button
                            Button(role: .destructive) {
                                binding.steps.remove(at: index)
                                renumberSteps(binding: &binding)
                                updateTimestamp()
                                dependencies.metrics.track(event: .stepDeleted)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .a11y(
                                id: "edit.step.delete.\(index)",
                                label: String.localizedStringWithFormat(String(localized: "a11y.edit.step.delete"), index + 1),
                                traits: .button
                            )
                        }
                        
                        StepRowView(step: $binding.steps[index])
                    }
                    .padding(.vertical, 8)
                    .a11y(
                        id: "edit.step.\(index)",
                        label: String.localizedStringWithFormat(String(localized: "a11y.edit.step.label"), index + 1)
                    )
                    .accessibilityActions {
                        if index > 0 {
                            AccessibilityAction(named: Text(String(localized: "a11y.edit.step.move_up"))) {
                                moveStepUp(binding: &binding, index: index)
                            }
                        }
                        if index < binding.steps.count - 1 {
                            AccessibilityAction(named: Text(String(localized: "a11y.edit.step.move_down"))) {
                                moveStepDown(binding: &binding, index: index)
                            }
                        }
                    }
                }
                .onMove(perform: moveSteps)
                
                Button(L10n.Edit.addTag) {
                    let next = binding.steps.count + 1
                    binding.steps.append(SOPStep(order: next, title: ""))
                    updateTimestamp()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .a11y(
                    id: "edit.add",
                    label: String(localized: "a11y.edit.add.label"),
                    traits: .button
                )
                .accessibilityHint(L10n.Accessibility.editAddStep)
            }
            .a11y(id: "edit.steps", label: String(localized: "a11y.edit.steps.label"))
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .accessibilityLabel(L10n.Edit.errorMessage)
                }
            }
        }
    }

    private func load() async {
        do {
            sop = try context.model(for: sopID) as? SOP
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateTimestamp() {
        sop?.updatedAt = .now
        try? context.save()
        dependencies.metrics.track(event: .sopEdited)
    }

    private func renumberSteps(binding: inout SOP) {
        for index in binding.steps.indices {
            binding.steps[index].order = index + 1
        }
    }
    
    private func moveSteps(from source: IndexSet, to destination: Int) {
        binding.steps.move(fromOffsets: source, toOffset: destination)
        renumberSteps(binding: &binding)
        updateTimestamp()
        dependencies.metrics.track(event: .stepReordered)
    }

    private func moveStepUp(binding: inout SOP, index: Int) {
        guard index > 0 else { return }
        binding.steps.swapAt(index, index - 1)
        renumberSteps(binding: &binding)
        updateTimestamp()
    }

    private func moveStepDown(binding: inout SOP, index: Int) {
        guard index < binding.steps.count - 1 else { return }
        binding.steps.swapAt(index, index + 1)
        renumberSteps(binding: &binding)
        updateTimestamp()
    }
}

private struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(L10n.Edit.toolPlaceholder, text: $newTag)
                    .textFieldStyle(.roundedBorder)
                Button(L10n.Edit.addStep) {
                    let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if !tags.contains(trimmed) {
                        tags.append(trimmed)
                    }
                    newTag = ""
                }
            }
            FlowLayout(tags: tags)
        }
    }
}

private struct FlowLayout: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
        }
    }
}
#if DEBUG
extension SOPEditView {
    @MainActor static func screenshotMock() -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: true)
        let result = ScreenshotEnvironment.makeContainerWithSampleSOP(isPro: true, status: .draft)
        return ScreenshotScene(dependencies: dependencies, container: result.container) {
            SOPEditView(sopID: result.sop.persistentModelID)
        }
    }
}
#endif

