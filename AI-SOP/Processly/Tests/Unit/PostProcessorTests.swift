import XCTest
@testable import Processly

final class PostProcessorTests: XCTestCase {
    func testClampAndSplitCompoundInstructions() throws {
        let step = LLMGenerationResponse.LLMStep(number: 1, instruction: "Mix batter and preheat oven then bake", notes: nil, estMinutes: 30)
        let response = makeResponse(title: "Weekly Cupcake SOP", steps: Array(repeating: step, count: 8))

        let result = try PostProcessor.sanitize(response: response, source: "", localeIdentifier: "en_US")

        XCTAssertEqual(result.response.steps.count, 15, "Steps should be clamped to 15 after splitting compound instructions.")
        XCTAssertEqual(result.response.steps.first?.instruction, "Mix batter")
        XCTAssertEqual(result.response.steps[1].instruction, "preheat oven")
        XCTAssertEqual(result.response.steps[2].instruction, "bake")
        XCTAssertTrue(result.response.title.count <= 60)
        XCTAssertFalse(result.response.title.contains("??"))
    }

    func testPIIRedactionAddsWarning() throws {
        let step = LLMGenerationResponse.LLMStep(number: 1, instruction: "Email results to ops@processly.com", notes: "Call +1 (555) 123-4567", estMinutes: 5)
        let response = makeResponse(summary: "Contact ops@processly.com", steps: [step])

        let result = try PostProcessor.sanitize(response: response, source: "ops@processly.com", localeIdentifier: "en_US")

        XCTAssertTrue(result.response.summary.contains("[REDACTED]"))
        XCTAssertTrue(result.response.steps[0].instruction.contains("[REDACTED]"))
        XCTAssertTrue(result.response.steps[0].notes?.contains("[REDACTED]") ?? false)
        XCTAssertTrue(result.response.warnings.contains(NSLocalizedString("Sensitive contact details were removed.", comment: "Redaction warning")))
        XCTAssertTrue(result.cleanedSource.contains("[REDACTED]"))
    }

    func testInvalidContractThrows() {
        let response = makeResponse(title: "Valid Title", steps: [])
        let validator = MockValidator(shouldThrow: true)

        XCTAssertThrowsError(try PostProcessor.sanitize(response: response, source: "", localeIdentifier: "en_US", validator: validator)) { error in
            XCTAssertTrue(error is PostProcessor.Error)
        }
    }

    func testValidContractPasses() throws {
        let steps = (1...3).map { index in
            LLMGenerationResponse.LLMStep(number: index, instruction: "Step \(index)", notes: nil, estMinutes: index * 2)
        }
        let response = makeResponse(steps: steps)

        let result = try PostProcessor.sanitize(response: response, source: "Raw source text", localeIdentifier: "en_US")
        XCTAssertEqual(result.response.steps.count, steps.count)
        XCTAssertEqual(result.response.steps.first?.number, 1)
        XCTAssertEqual(result.response.steps.last?.estMinutes, 6)
    }

    func testNonEnglishLocaleSkipsCompoundSplits() throws {
        let step = LLMGenerationResponse.LLMStep(number: 1, instruction: "Mix batter and preheat oven then bake", notes: nil, estMinutes: 10)
        let response = makeResponse(title: "????? ??????", steps: [step])

        let result = try PostProcessor.sanitize(response: response, source: "", localeIdentifier: "he_IL")

        XCTAssertEqual(result.response.steps.count, 1, "Non-English locales should not split compound instructions aggressively")
    }

    // MARK: - Helpers

    private func makeResponse(
        title: String = "Sample Title",
        summary: String = "Summary",
        steps: [LLMGenerationResponse.LLMStep]
    ) -> LLMGenerationResponse {
        LLMGenerationResponse(
            title: title,
            summary: summary,
            toolsNeeded: ["Tool"],
            steps: steps,
            warnings: [],
            tags: ["tag"]
        )
    }
}

private struct MockValidator: JSONValidating {
    let shouldThrow: Bool

    func validate(_ data: Data) throws {
        if shouldThrow {
            throw NSError(domain: "MockValidator", code: -1)
        }
    }
}
