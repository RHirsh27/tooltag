import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @Environment(\.modelContext) private var context
    @Query(sort: \SOP.updatedAt, order: .reverse) private var sops: [SOP]
    @State private var searchText = ""

    var body: some View {
        VStack {
            if dependencies.networkMonitor.isOffline {
                offlineBanner
            }
            header
            actionButtons
            list
        }
        .padding()
        .navigationTitle(L10n.Home.title)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Home.welcome)
                .font(.title2)
            Text(L10n.Home.subtitle)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                dependencies.metrics.track(event: .captureStarted(mode: .voice))
                dependencies.router.push(.capture)
            } label: {
                Label(L10n.Home.recordCTA, systemImage: "mic.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .a11y(
                id: "home.record",
                label: String(localized: "home.record.button"),
                traits: .button
            )
            .accessibilityHint(L10n.Home.recordHint)

            Button {
                dependencies.metrics.track(event: .captureStarted(mode: .text))
                dependencies.router.push(.paste)
            } label: {
                Label(L10n.Home.pasteCTA, systemImage: "doc.on.clipboard")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }
            .a11y(
                id: "home.paste",
                label: String(localized: "home.paste.button"),
                traits: .button
            )
            .accessibilityHint(L10n.Home.pasteHint)
        }
    }

    private var list: some View {
        List {
            if filteredSOPs.isEmpty {
                Text(L10n.Home.emptyMessage)
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredSOPs) { sop in
                    SOPListItemView(sop: sop)
                        .onTapGesture {
                            dependencies.router.push(.edit(sopID: sop.persistentModelID))
                        }
                }
            }
        }
        .listStyle(.plain)
        .a11y(id: "home.recent", label: String(localized: "home.recent.label"))
        .searchable(text: $searchText)
    }

    private var filteredSOPs: [SOP] {
        guard !searchText.isEmpty else { return sops }
        return sops.filter { sop in
            sop.title.localizedCaseInsensitiveContains(searchText) ||
            sop.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
            Text("Offline — actions will queue.")
                .font(.caption)
                .foregroundColor(.orange)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
