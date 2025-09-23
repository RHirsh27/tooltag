import Foundation
import SwiftData

@MainActor
enum SeedData {
    static func ensureDefaults(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<SOP>(fetchLimit: 1)
            if try context.fetch(descriptor).isEmpty {
                let templates = TemplateRepository().loadDefaultTemplates()
                templates.forEach { template in
                    let sop = SOP(
                        title: template.title,
                        summary: template.summary,
                        tags: template.tags,
                        tools: template.tools,
                        steps: template.steps,
                        sourceRaw: "Seed",
                        status: .draft
                    )
                    context.insert(sop)
                }
                try context.save()
            }
        } catch {
            // TODO: Surface seeding error to telemetry.
        }
    }
}
