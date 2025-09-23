import SwiftUI

struct PasteTextView: View {
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @State private var input = ""
    @State private var isGenerating = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Paste Your Text")
                    .font(.headline)
                
                Text("Paste or type your process description here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $input)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                if input.isEmpty {
                    Text("Describe your process here...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            
            Button("Generate Process") {
                generateProcess()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
            
            if isGenerating {
                ProgressView("Generating...")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .navigationTitle("Text Input")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dependencies.router.pop()
                }
            }
        }
    }
    
    private func generateProcess() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isGenerating = true
        let job = GenerationJob(rawText: trimmed, localeIdentifier: Locale.current.identifier)
        dependencies.generationQueue.enqueue(job)
        dependencies.router.push(.generate(jobID: job.id))
        isGenerating = false
    }
}