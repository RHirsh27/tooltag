import SwiftUI
import SwiftData

enum AppRoute: Hashable {
    case onboarding
    case capture
    case paste
    case generate(jobID: UUID)
    case edit(sopID: PersistentIdentifier)
    case finalize(sopID: PersistentIdentifier)
    case export(sopID: PersistentIdentifier)
    case paywall(trigger: PaywallTrigger)
    case settings
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .onboarding:
            OnboardingView()
        case .capture:
            CaptureView()
        case .paste:
            PasteTextView()
        case .generate(let jobID):
            GenerateView(jobID: jobID)
        case .edit(let sopID):
            SOPEditView(sopID: sopID)
        case .finalize(let sopID):
            FinalizeView(sopID: sopID)
        case .export(let sopID):
            ExportView(sopID: sopID)
        case .paywall(let trigger):
            PaywallView(trigger: trigger)
        case .settings:
            SettingsView()
        }
    }
}

enum PaywallTrigger: String, Hashable {
    case quota
    case premiumExport
}
