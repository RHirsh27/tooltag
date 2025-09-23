import SwiftUI

struct SOPListItemView: View {
    let sop: SOP

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sop.title)
                    .font(.headline)
                Text(sop.summary)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                tags
            }
            Spacer()
            statusBadge
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
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
}
