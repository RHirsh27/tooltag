import SwiftUI
import SwiftData
import UIKit

struct ExportView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @EnvironmentObject private var iapService: IAPService
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    let sopID: PersistentIdentifier
    @State private var sop: SOP?
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var previewURL: URL?
    @State private var showingPreview = false
    @State private var lastIncludeWatermark = false
    @State private var errorMessage: String?

    private var formatDisplayName: String {
        switch selectedFormat {
        case .pdf: return "PDF"
        case .docx: return "DOCX"
        case .markdown: return "Markdown"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Picker(String(localized: "export.format.label"), selection: $selectedFormat) {
                Text("PDF").tag(ExportFormat.pdf)
                Text("DOCX").tag(ExportFormat.docx)
                Text("Markdown").tag(ExportFormat.markdown)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedFormat, perform: handleFormatChange)
            .a11y(
                id: "export.format",
                label: String.localizedStringWithFormat(String(localized: "a11y.export.format.label"), formatDisplayName)
            )

            if differentiateWithoutColor {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                    Text(String.localizedStringWithFormat(String(localized: "export.format.caption"), formatDisplayName))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let sop {
                Button(String(localized: "export.cta.title")) {
                    Task { await export(sop: sop) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .a11y(
                    id: "export.cta",
                    label: String(localized: "a11y.export.cta.label"),
                    hint: String(localized: "a11y.export.cta.hint"),
                    traits: .button
                )
                .disabled(!isFormatAllowed)
            } else {
                ProgressView()
                    .task(load)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            if FeatureFlags.enableDebugToasts {
                VStack {
                    Text("Debug Mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Environment: \(FeatureFlags.isProd ? "PROD" : "DEV")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
            }
        }
        .padding()
        .navigationTitle("Export")
        .background(
            NavigationLink(isActive: $showingPreview) {
                if let url = previewURL, let sop {
                    ExportPreviewView(sop: sop, fileURL: url, format: selectedFormat, showsWatermark: lastIncludeWatermark)
                } else {
                    EmptyView()
                }
            } label: {
                EmptyView()
            }
        )
        .task {
            await load()
        }
    }

    private var isFormatAllowed: Bool {
        switch selectedFormat {
        case .pdf:
            return true
        case .docx, .markdown:
            return iapService.hasAccess(.exportPremium)
        }
    }

    private func handleFormatChange(_ newValue: ExportFormat) {
        if (newValue == .docx || newValue == .markdown) && !iapService.hasAccess(.exportPremium) {
            dependencies.presentToast(NSLocalizedString("Upgrade to export DOCX or Markdown.", comment: "Premium export toast"))
            dependencies.router.push(.paywall(trigger: .premiumExport))
        }
    }

    private func load() async {
        do {
            sop = try context.model(for: sopID) as? SOP
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func export(sop: SOP) async {
        do {
            let includeWatermark = !iapService.hasAccess(.exportPremium)
            let url = try await dependencies.exportService.export(
                sop: sop,
                format: selectedFormat,
                includeWatermark: includeWatermark
            )
            lastIncludeWatermark = includeWatermark
            previewURL = url
            showingPreview = true
        } catch {
            errorMessage = error.localizedDescription
            dependencies.metrics.track(event: .error(type: .export, context: error.localizedDescription))
        }
    }
}
