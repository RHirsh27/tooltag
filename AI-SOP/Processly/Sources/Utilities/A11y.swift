import SwiftUI
import UIKit

extension View {
    func a11y(
        id: String? = nil,
        label: String? = nil,
        hint: String? = nil,
        traits: UIAccessibilityTraits? = nil
    ) -> some View {
        var modified = AnyView(self)
        if let id {
            modified = AnyView(modified.accessibilityIdentifier(id))
        }
        if let label {
            modified = AnyView(modified.accessibilityLabel(Text(label)))
        }
        if let hint {
            modified = AnyView(modified.accessibilityHint(Text(hint)))
        }
        if let traits {
            modified = AnyView(modified.accessibilityAddTraits(traits))
        }
        return modified
    }
}

private struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isReduceMotionEnabled
}

private struct DifferentiateWithoutColorKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.shouldDifferentiateWithoutColor
}

extension EnvironmentValues {
    var isReduceMotionEnabled: Bool {
        self[ReduceMotionKey.self]
    }

    var shouldDifferentiateWithoutColor: Bool {
        self[DifferentiateWithoutColorKey.self]
    }
}
