import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let applicationActivities: [UIActivity]?
    
    init(items: [Any], applicationActivities: [UIActivity]? = nil) {
        self.items = items
        self.applicationActivities = applicationActivities
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        
        // Configure for iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Convenience Extensions

extension ShareSheet {
    static func shareFile(_ url: URL) -> ShareSheet {
        ShareSheet(items: [url])
    }
    
    static func shareFiles(_ urls: [URL]) -> ShareSheet {
        ShareSheet(items: urls)
    }
    
    static func shareText(_ text: String) -> ShareSheet {
        ShareSheet(items: [text])
    }
    
    static func shareSOP(_ sop: SOP, format: ExportFormat) -> ShareSheet {
        let text = "Check out this SOP: \(sop.title)"
        return ShareSheet(items: [text])
    }
}

// MARK: - Share Button Component

struct ShareButton: View {
    let items: [Any]
    let applicationActivities: [UIActivity]?
    let shareType: String
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @State private var showingShareSheet = false
    
    init(items: [Any], applicationActivities: [UIActivity]? = nil, shareType: String = "file") {
        self.items = items
        self.applicationActivities = applicationActivities
        self.shareType = shareType
    }
    
    var body: some View {
        Button {
            dependencies.metrics.track(event: .shareInitiated, properties: ["type": shareType])
            showingShareSheet = true
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: items, applicationActivities: applicationActivities)
                .onAppear {
                    dependencies.metrics.track(event: .shareCompleted, properties: ["type": shareType])
                }
        }
    }
}

// MARK: - Convenience Share Buttons

extension ShareButton {
    static func shareFile(_ url: URL) -> ShareButton {
        ShareButton(items: [url])
    }
    
    static func shareFiles(_ urls: [URL]) -> ShareButton {
        ShareButton(items: urls)
    }
    
    static func shareText(_ text: String) -> ShareButton {
        ShareButton(items: [text])
    }
}
