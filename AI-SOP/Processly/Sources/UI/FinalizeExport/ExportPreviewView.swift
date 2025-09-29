import SwiftUI
import QuickLook

struct ExportPreviewView: View {
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @EnvironmentObject private var iapService: IAPService
    let sop: SOP
    let fileURL: URL
    let format: ExportFormat
    let showsWatermark: Bool
    
    @State private var selectedFormat: ExportFormat
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showingQuickLook = false
    @State private var showingShareSheet = false
    @State private var currentExportURL: URL?
    
    init(sop: SOP, fileURL: URL, format: ExportFormat, showsWatermark: Bool) {
        self.sop = sop
        self.fileURL = fileURL
        self.format = format
        self.showsWatermark = showsWatermark
        self._selectedFormat = State(initialValue: format)
        self._currentExportURL = State(initialValue: fileURL)
    }

    var body: some View {
        VStack(spacing: 20) {
            previewSection
            
            formatPicker
            
            if showsWatermark {
                watermarkNotice
            }
            
            exportButton
            
            if let exportError {
                Text(exportError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle("Export Preview")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dependencies.router.pop()
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                if let currentExportURL = currentExportURL {
                    ShareButton.shareFile(currentExportURL)
                }
            }
        }
    }
    
    private var previewSection: some View {
        VStack {
            if format == .pdf {
                Button("Preview PDF") {
                    showingQuickLook = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                VStack {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Preview not available for \(format.rawValue.uppercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var formatPicker: some View {
        Picker("Export Format", selection: $selectedFormat) {
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Text(format.rawValue.uppercased()).tag(format)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var watermarkNotice: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Free version includes watermark")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var exportButton: some View {
        Button("Export \(selectedFormat.rawValue.uppercased())") {
            Task { await export() }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isExporting)
    }
    
    private func export() async {
        isExporting = true
        exportError = nil
        
        do {
            let includeWatermark = !iapService.hasAccess(.exportPremium)
            let newURL = try await dependencies.exportService.export(
                sop: sop,
                format: selectedFormat,
                includeWatermark: includeWatermark
            )
            currentExportURL = newURL
        } catch {
            exportError = error.localizedDescription
        }
        
        isExporting = false
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}