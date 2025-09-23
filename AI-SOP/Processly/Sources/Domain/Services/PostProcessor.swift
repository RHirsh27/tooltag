import Foundation

protocol JSONValidating {
    func validate(_ data: Data) throws
}

extension JSONSchemaValidator: JSONValidating {}

/// Sanitizes LLM output into an app-safe representation before persistence or export.
struct PostProcessor {
    struct Result {
        let response: LLMGenerationResponse
        let cleanedSource: String
    }

    enum Error: Swift.Error {
        case invalidContract
    }

    private enum Constants {
        static let maxSteps = 15
        static let compoundRegex = "(?i)\\s+(?:and|then)\\s+"
        static let redactedPlaceholder = "[REDACTED]"
    }

    static func sanitize(
        response: LLMGenerationResponse,
        source: String,
        localeIdentifier: String? = nil,
        validator: JSONValidating = JSONSchemaValidator()
    ) throws -> Result {
        let sanitizedTitle = sanitizeTitle(response.title)
        let (summary, summaryRedacted) = redactPII(in: response.summary)
        let (tools, toolsRedacted) = sanitizeList(response.toolsNeeded)
        let (tags, _) = sanitizeList(response.tags)

        let shouldSplit = shouldSplitCompound(for: localeIdentifier)
        let sanitizedSteps = clamp(
            steps: splitAndSanitizeSteps(response.steps, shouldSplitCompound: shouldSplit)
        )

        let stepsRedacted = sanitizedSteps.contains { step in
            step.instruction.contains(Constants.redactedPlaceholder) || (step.notes?.contains(Constants.redactedPlaceholder) ?? false)
        }

        var warnings = response.warnings
        if summaryRedacted || toolsRedacted || stepsRedacted {
            let warning = NSLocalizedString("Sensitive contact details were removed.", comment: "Redaction warning")
            if warnings.contains(warning) == false {
                warnings.append(warning)
            }
        }

        let (cleanSource, _) = redactPII(in: source)

        let sanitized = LLMGenerationResponse(
            title: sanitizedTitle,
            summary: summary,
            toolsNeeded: tools,
            steps: sanitizedSteps,
            warnings: warnings,
            tags: tags
        )

        let promptResponse = PromptResponse(
            title: sanitized.title,
            summary: sanitized.summary,
            tools_needed: sanitized.toolsNeeded,
            steps: sanitized.steps.map { step in
                PromptResponse.PromptStep(
                    number: step.number,
                    instruction: step.instruction,
                    notes: step.notes,
                    est_minutes: step.estMinutes
                )
            },
            warnings: sanitized.warnings,
            tags: sanitized.tags
        )

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(promptResponse)
            try validator.validate(data)
        } catch {
            throw Error.invalidContract
        }

        return Result(response: sanitized, cleanedSource: cleanSource)
    }

    // MARK: - Helpers

    private static func shouldSplitCompound(for localeIdentifier: String?) -> Bool {
        guard let identifier = localeIdentifier ?? Locale.current.identifier else { return true }
        let locale = Locale(identifier: identifier)
        return locale.language.languageCode?.identifier.lowercased().hasPrefix("en") ?? true
    }

    private static func sanitizeTitle(_ title: String) -> String {
        let stripped = title.filter { character in
            character.unicodeScalars.allSatisfy { scalar in
                !scalar.properties.isEmojiPresentation && !scalar.properties.isEmoji
            }
        }
        let trimmed = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 60 {
            return trimmed.isEmpty ? defaultTitle() : trimmed
        }
        return String(trimmed.prefix(60)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func defaultTitle() -> String {
        NSLocalizedString("Standard Operating Procedure", comment: "Fallback title")
    }

    private static func sanitizeList(_ values: [String]) -> ([String], Bool) {
        var redacted = false
        let sanitized = values.map { value -> String in
            let (sanitizedValue, wasRedacted) = redactPII(in: value)
            if wasRedacted { redacted = true }
            return sanitizedValue
        }
        return (sanitized, redacted)
    }

    private static func splitAndSanitizeSteps(_ steps: [LLMGenerationResponse.LLMStep], shouldSplitCompound: Bool) -> [LLMGenerationResponse.LLMStep] {
        var output: [LLMGenerationResponse.LLMStep] = []
        steps.forEach { step in
            let (instruction, _) = redactPII(in: step.instruction)
            let noteValue: String? = {
                guard let note = step.notes else { return nil }
                let (sanitizedNote, _) = redactPII(in: note)
                let trimmed = sanitizedNote.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }()
            let fragments = shouldSplitCompound ? splitCompound(instruction) : [instruction]
            if fragments.count <= 1 {
                output.append(
                    LLMGenerationResponse.LLMStep(
                        number: output.count + 1,
                        instruction: instruction.trimmingCharacters(in: .whitespacesAndNewlines),
                        notes: noteValue,
                        estMinutes: step.estMinutes
                    )
                )
            } else {
                for (idx, piece) in fragments.enumerated() {
                    output.append(
                        LLMGenerationResponse.LLMStep(
                            number: output.count + 1,
                            instruction: piece.trimmingCharacters(in: .whitespacesAndNewlines),
                            notes: idx == 0 ? noteValue : nil,
                            estMinutes: step.estMinutes
                        )
                    )
                }
            }
        }
        return renumber(output)
    }

    private static func clamp(steps: [LLMGenerationResponse.LLMStep]) -> [LLMGenerationResponse.LLMStep] {
        let limited = Array(steps.prefix(Constants.maxSteps))
        return renumber(limited)
    }

    private static func renumber(_ steps: [LLMGenerationResponse.LLMStep]) -> [LLMGenerationResponse.LLMStep] {
        steps.enumerated().map { index, step in
            LLMGenerationResponse.LLMStep(
                number: index + 1,
                instruction: step.instruction,
                notes: step.notes,
                estMinutes: step.estMinutes
            )
        }
    }

    private static func splitCompound(_ instruction: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: Constants.compoundRegex, options: []) else {
            return [instruction]
        }
        let range = NSRange(instruction.startIndex..<instruction.endIndex, in: instruction)
        let placeholder = "|SPLIT|"
        let replaced = regex.stringByReplacingMatches(in: instruction, options: [], range: range, withTemplate: placeholder)
        return replaced
            .components(separatedBy: placeholder)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func redactPII(in text: String) -> (String, Bool) {
        guard text.isEmpty == false else { return (text, false) }
        var mutableText = text
        var redacted = false

        let patterns = [
            "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
            "\\b(?:\\+?\\d{1,3}[\\s-]?)?(?:\\(\\d{3}\\)|\\d{3})[\\s-]?\\d{3}[\\s-]?\\d{4}\\b"
        ]

        patterns.forEach { pattern in
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(mutableText.startIndex..<mutableText.endIndex, in: mutableText)
                let matches = regex.matches(in: mutableText, options: [], range: range)
                if matches.isEmpty == false {
                    redacted = true
                }
                mutableText = regex.stringByReplacingMatches(
                    in: mutableText,
                    options: [],
                    range: range,
                    withTemplate: Constants.redactedPlaceholder
                )
            }
        }

        return (mutableText, redacted)
    }
}
