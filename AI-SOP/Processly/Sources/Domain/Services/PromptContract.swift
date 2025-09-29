import Foundation
import SwiftUI

enum PromptStyle {
    case sop
    case summary
    case extract
}

struct PromptBuilder {
    static func make(from raw: String, locale: Locale, style: PromptStyle) -> String {
        let systemDirectives = "You are a process documentation expert. Create clear, actionable steps."
        let localeHints = "Use \(locale.languageCode ?? "en") language conventions."
        let clamped = String(raw.prefix(4000))
        return "\(systemDirectives)\n\n\(localeHints)\n\n\(clamped)"
    }
}

enum PromptContract {
    static let systemPrompt = "You transform messy notes into a concise, actionable SOP."

    static func makeUserPayload(
        rawText: String,
        titleHint: String?,
        includeTools: Bool,
        maxSteps: Int,
        tone: String
    ) -> PromptPayload {
        PromptPayload(
            raw_text: rawText,
            title_hint: titleHint,
            include_tools: includeTools,
            max_steps: min(15, maxSteps),
            tone: tone
        )
    }
}

struct PromptPayload: Codable {
    let raw_text: String
    let title_hint: String?
    let include_tools: Bool
    let max_steps: Int
    let tone: String
}

struct PromptResponse: Codable {
    let title: String
    let summary: String
    let tools_needed: [String]
    let steps: [PromptStep]
    let warnings: [String]
    let tags: [String]

    struct PromptStep: Codable {
        let number: Int
        let instruction: String
        let notes: String?
        let est_minutes: Int?
    }
}
