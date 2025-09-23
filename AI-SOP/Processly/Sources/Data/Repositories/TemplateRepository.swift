import Foundation

struct SOPTemplate: Identifiable, Hashable {
    let id: UUID
    let title: String
    let summary: String
    let tools: [String]
    let steps: [SOPStep]
    let tags: [String]

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        tools: [String],
        steps: [SOPStep],
        tags: [String]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.tools = tools
        self.steps = steps
        self.tags = tags
    }
}

final class TemplateRepository {
    func loadDefaultTemplates() -> [SOPTemplate] {
        // TODO: Localize template copy.
        return [
            SOPTemplate(
                title: "Podcast Episode Prep",
                summary: "Prepare an episode outline and assets before recording.",
                tools: ["Calendar", "Google Docs", "Microphone"],
                steps: [
                    SOPStep(number: 1, instruction: "Review listener feedback", notes: nil, estMinutes: 15),
                    SOPStep(number: 2, instruction: "Draft episode outline", notes: nil, estMinutes: 45),
                    SOPStep(number: 3, instruction: "Source guest assets", notes: "Headshot, bio", estMinutes: 20)
                ],
                tags: ["content", "podcast"]
            ),
            SOPTemplate(
                title: "Client Onboarding Call",
                summary: "Standardize the agenda for a new client kickoff call.",
                tools: ["Video Conferencing", "CRM"],
                steps: [
                    SOPStep(number: 1, instruction: "Send kickoff agenda", notes: nil, estMinutes: 5),
                    SOPStep(number: 2, instruction: "Review client's objectives", notes: nil, estMinutes: 20),
                    SOPStep(number: 3, instruction: "Confirm next steps", notes: nil, estMinutes: 10)
                ],
                tags: ["client", "onboarding"]
            ),
            SOPTemplate(
                title: "Weekly Marketing Report",
                summary: "Compile weekly marketing performance metrics.",
                tools: ["Analytics Dashboard", "Spreadsheet"],
                steps: [
                    SOPStep(number: 1, instruction: "Export KPI data", notes: nil, estMinutes: 15),
                    SOPStep(number: 2, instruction: "Summarize channel highlights", notes: nil, estMinutes: 20),
                    SOPStep(number: 3, instruction: "Publish report", notes: "Send via Slack + email", estMinutes: 10)
                ],
                tags: ["marketing", "reporting"]
            ),
            SOPTemplate(
                title: "Incident Response Intake",
                summary: "Capture key details for reported incidents.",
                tools: ["Ticketing System"],
                steps: [
                    SOPStep(number: 1, instruction: "Acknowledge reporter", notes: nil, estMinutes: 5),
                    SOPStep(number: 2, instruction: "Gather incident details", notes: "Impact, timeline", estMinutes: 15),
                    SOPStep(number: 3, instruction: "Assign responder", notes: nil, estMinutes: 5)
                ],
                tags: ["operations", "support"]
            ),
            SOPTemplate(
                title: "Daily Standup Notes",
                summary: "Document blockers and priorities for the team standup.",
                tools: ["Project Management Tool"],
                steps: [
                    SOPStep(number: 1, instruction: "List yesterday's accomplishments", notes: nil, estMinutes: 5),
                    SOPStep(number: 2, instruction: "Capture today's focus", notes: nil, estMinutes: 5),
                    SOPStep(number: 3, instruction: "Flag blockers", notes: nil, estMinutes: 5)
                ],
                tags: ["team", "agile"]
            )
        ]
    }
}
