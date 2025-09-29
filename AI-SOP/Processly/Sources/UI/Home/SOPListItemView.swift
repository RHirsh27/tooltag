import SwiftUI

struct SOPListItemView: View {
    let sop: SOP
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @State private var showingShareSheet = false
    @State private var exportedURL: URL?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sop.title)
                    .font(.headline)
                Text(sop.summary ?? "")
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                tags
            }
            Spacer()
            
            HStack(spacing: 8) {
                statusBadge
                
                Button {
                    Task {
                        await shareSOP()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedURL {
                ShareSheet.shareFile(url)
            }
        }
    }

    private var statusBadge: some View {
        Text(sop.status == .final ? "Final" : "Draft")
            .font(.caption)
            .padding(6)
            .background(sop.status == .final ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            .cornerRadius(8)
    }

    private var tags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(sop.tags, id: \.self) { tag in
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
    
    private func shareSOP() async {
        do {
            // Export as PDF for sharing (most compatible format)
            let url = try await dependencies.exportService.export(
                sop: sop,
                format: .pdf,
                includeWatermark: true // Use watermark for quick sharing
            )
            exportedURL = url
            showingShareSheet = true
        } catch {
            // Handle error silently for now
            print("Failed to export SOP for sharing: \(error)")
        }
    }
}
