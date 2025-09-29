import Foundation
import SwiftData

@MainActor
protocol TemplateService {
    func createTemplate(from sop: SOP) async throws -> Template
    func duplicateTemplate(_ template: Template) async throws -> SOP
    func loadDefaultTemplates() async throws -> [Template]
    func deleteTemplate(_ template: Template) async throws
}

@MainActor
final class DefaultTemplateService: TemplateService {
    private let context: ModelContext
    private let metrics: MetricsReporter
    
    init(context: ModelContext, metrics: MetricsReporter) {
        self.context = context
        self.metrics = metrics
    }
    
    func createTemplate(from sop: SOP) async throws -> Template {
        // Create a copy of the SOP for the template
        let templateSOP = SOP(
            title: sop.title,
            summary: sop.summary,
            tags: sop.tags,
            estimatedDurationMin: sop.estimatedDurationMin,
            coverImageData: sop.coverImageData,
            isFavorite: false,
            steps: sop.steps.map { step in
                SOPStep(
                    order: step.order,
                    title: step.title,
                    details: step.details,
                    checklistItems: step.checklistItems.map { item in
                        ChecklistItem(text: item.text, isRequired: item.isRequired)
                    },
                    attachmentLocalURL: step.attachmentLocalURL,
                    voiceNoteLocalURL: step.voiceNoteLocalURL,
                    durationMin: step.durationMin
                )
            },
            sourceRaw: "Template",
            status: .draft
        )
        
        let template = Template(
            name: sop.title,
            description: sop.summary,
            sample: false,
            sopDraft: templateSOP
        )
        
        context.insert(template)
        try context.save()
        
        metrics.track(event: .templateCreated)
        return template
    }
    
    func duplicateTemplate(_ template: Template) async throws -> SOP {
        // Create a new SOP from the template
        let newSOP = SOP(
            title: template.sopDraft.title,
            summary: template.sopDraft.summary,
            tags: template.sopDraft.tags,
            estimatedDurationMin: template.sopDraft.estimatedDurationMin,
            coverImageData: template.sopDraft.coverImageData,
            isFavorite: false,
            steps: template.sopDraft.steps.map { step in
                SOPStep(
                    order: step.order,
                    title: step.title,
                    details: step.details,
                    checklistItems: step.checklistItems.map { item in
                        ChecklistItem(text: item.text, isRequired: item.isRequired)
                    },
                    attachmentLocalURL: step.attachmentLocalURL,
                    voiceNoteLocalURL: step.voiceNoteLocalURL,
                    durationMin: step.durationMin
                )
            },
            sourceRaw: "Template Duplicate",
            status: .draft
        )
        
        context.insert(newSOP)
        try context.save()
        
        metrics.track(event: .templateDuplicated)
        return newSOP
    }
    
    func loadDefaultTemplates() async throws -> [Template] {
        // Check if templates already exist
        let descriptor = FetchDescriptor<Template>(fetchLimit: 1)
        let existingTemplates = try context.fetch(descriptor)
        
        if !existingTemplates.isEmpty {
            return try context.fetch(FetchDescriptor<Template>())
        }
        
        // Create default templates
        let defaultTemplates = createDefaultTemplates()
        
        for template in defaultTemplates {
            context.insert(template)
        }
        
        try context.save()
        return defaultTemplates
    }
    
    func deleteTemplate(_ template: Template) async throws {
        context.delete(template)
        try context.save()
        
        metrics.track(event: .templateDeleted)
    }
    
    private func createDefaultTemplates() -> [Template] {
        return [
            createTemplate(
                name: "Podcast Episode Prep",
                description: "Prepare an episode outline and assets before recording.",
                steps: [
                    ("Review listener feedback", "Check comments and feedback from previous episodes", 15),
                    ("Draft episode outline", "Create structured outline with key talking points", 45),
                    ("Source guest assets", "Collect headshot, bio, and any promotional materials", 20)
                ],
                tags: ["content", "podcast"]
            ),
            createTemplate(
                name: "Client Onboarding Call",
                description: "Standardize the agenda for a new client kickoff call.",
                steps: [
                    ("Send kickoff agenda", "Email agenda and meeting details to client", 5),
                    ("Review client's objectives", "Understand their goals and expectations", 20),
                    ("Confirm next steps", "Document action items and follow-up schedule", 10)
                ],
                tags: ["client", "onboarding"]
            ),
            createTemplate(
                name: "Weekly Marketing Report",
                description: "Compile weekly marketing performance metrics.",
                steps: [
                    ("Export KPI data", "Pull data from analytics dashboard", 15),
                    ("Summarize channel highlights", "Identify top performing channels and campaigns", 20),
                    ("Publish report", "Share findings via Slack and email", 10)
                ],
                tags: ["marketing", "reporting"]
            ),
            createTemplate(
                name: "Incident Response Intake",
                description: "Capture key details for reported incidents.",
                steps: [
                    ("Acknowledge reporter", "Confirm receipt and set expectations", 5),
                    ("Gather incident details", "Collect impact assessment and timeline", 15),
                    ("Assign responder", "Route to appropriate team member", 5)
                ],
                tags: ["operations", "support"]
            ),
            createTemplate(
                name: "Daily Standup Notes",
                description: "Document blockers and priorities for the team standup.",
                steps: [
                    ("List yesterday's accomplishments", "Review completed tasks and progress", 5),
                    ("Capture today's focus", "Identify key priorities for the day", 5),
                    ("Flag blockers", "Note any impediments or dependencies", 5)
                ],
                tags: ["team", "agile"]
            )
        ]
    }
    
    private func createTemplate(
        name: String,
        description: String,
        steps: [(String, String, Int)],
        tags: [String]
    ) -> Template {
        let sopSteps = steps.enumerated().map { index, step in
            SOPStep(
                order: index + 1,
                title: step.0,
                details: step.1,
                durationMin: step.2
            )
        }
        
        let sopDraft = SOP(
            title: name,
            summary: description,
            tags: tags,
            steps: sopSteps,
            sourceRaw: "Default Template",
            status: .draft
        )
        
        return Template(
            name: name,
            description: description,
            sample: true,
            sopDraft: sopDraft
        )
    }
}
