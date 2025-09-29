import SwiftUI
import SwiftData

struct StepRowView: View {
    @Binding var step: SOPStep
    @Environment(\.modelContext) private var context
    @State private var showingChecklistEditor = false
    @State private var showingAttachmentPicker = false
    @State private var showingVoiceRecorder = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step Title
            TextField("Step title", text: $step.title)
                .font(.headline)
                .textFieldStyle(.roundedBorder)
            
            // Step Details
            TextField("Step details (optional)", text: Binding(
                get: { step.details ?? "" },
                set: { step.details = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
            
            // Duration and Checklist Row
            HStack {
                // Duration
                HStack {
                    Text("Duration:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("min", text: Binding(
                        get: { step.durationMin.map { String($0) } ?? "" },
                        set: { step.durationMin = Int($0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .keyboardType(.numberPad)
                    Text("min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Checklist Button
                Button {
                    showingChecklistEditor = true
                } label: {
                    Label("Checklist", systemImage: "checklist")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Attachments Row
            HStack {
                // Attachments
                Button {
                    showingAttachmentPicker = true
                } label: {
                    Label("Add File", systemImage: "paperclip")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Voice Note
                Button {
                    showingVoiceRecorder = true
                } label: {
                    Label("Voice Note", systemImage: "mic")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                // Attachment indicators
                if step.attachmentLocalURL != nil {
                    Image(systemName: "paperclip.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                if step.voiceNoteLocalURL != nil {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // Checklist Items Preview
            if !step.checklistItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Checklist Items:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(step.checklistItems) { item in
                        HStack {
                            Image(systemName: item.isRequired ? "exclamationmark.circle.fill" : "circle")
                                .foregroundColor(item.isRequired ? .orange : .secondary)
                                .font(.caption)
                            Text(item.text)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingChecklistEditor) {
            ChecklistEditorView(step: $step)
        }
        .sheet(isPresented: $showingAttachmentPicker) {
            DocumentPicker { url in
                step.attachmentLocalURL = url
            }
        }
        .sheet(isPresented: $showingVoiceRecorder) {
            VoiceRecorderView { url in
                step.voiceNoteLocalURL = url
            }
        }
    }
}

// MARK: - Checklist Editor
struct ChecklistEditorView: View {
    @Binding var step: SOPStep
    @Environment(\.dismiss) private var dismiss
    @State private var newItemText = ""
    @State private var newItemRequired = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Add new item
                HStack {
                    TextField("New checklist item", text: $newItemText)
                        .textFieldStyle(.roundedBorder)
                    
                    Toggle("Required", isOn: $newItemRequired)
                        .labelsHidden()
                    
                    Button("Add") {
                        addItem()
                    }
                    .disabled(newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                
                // Items list
                List {
                    ForEach(step.checklistItems) { item in
                        HStack {
                            Image(systemName: item.isRequired ? "exclamationmark.circle.fill" : "circle")
                                .foregroundColor(item.isRequired ? .orange : .secondary)
                            
                            Text(item.text)
                            
                            Spacer()
                            
                            Button("Delete") {
                                deleteItem(item)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .onMove(perform: moveItems)
                }
            }
            .navigationTitle("Checklist Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addItem() {
        let text = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let item = ChecklistItem(text: text, isRequired: newItemRequired)
        step.checklistItems.append(item)
        
        newItemText = ""
        newItemRequired = false
    }
    
    private func deleteItem(_ item: ChecklistItem) {
        step.checklistItems.removeAll { $0.id == item.id }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        step.checklistItems.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

// MARK: - Voice Recorder
struct VoiceRecorderView: View {
    let onRecordingComplete: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var recordingURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 60))
                    .foregroundColor(isRecording ? .red : .primary)
                
                Text(isRecording ? "Recording..." : "Tap to start recording")
                    .font(.headline)
                
                if let url = recordingURL {
                    Text("Recording saved")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                HStack(spacing: 20) {
                    Button(isRecording ? "Stop" : "Record") {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if recordingURL != nil {
                        Button("Use Recording") {
                            onRecordingComplete(recordingURL!)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
            }
            .padding()
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startRecording() {
        // TODO: Implement actual voice recording
        isRecording = true
        recordingURL = URL(fileURLWithPath: "/tmp/voice_note.m4a")
    }
    
    private func stopRecording() {
        isRecording = false
    }
}
