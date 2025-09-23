import SwiftUI

struct StepRowView: View {
    @Binding var step: SOPStep

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(L10n.Edit.stepInstructionPlaceholder, text: $step.instruction)
            TextField(L10n.Edit.stepNotesPlaceholder, text: Binding(
                get: { step.notes ?? "" },
                set: { step.notes = $0.isEmpty ? nil : $0 }
            ))
            TextField(L10n.Edit.stepMinutesPlaceholder, text: Binding(
                get: { step.estMinutes.map { String($0) } ?? "" },
                set: { step.estMinutes = Int($0) }
            ))
            .keyboardType(.numberPad)
        }
        .padding(.vertical, 8)
    }
}
