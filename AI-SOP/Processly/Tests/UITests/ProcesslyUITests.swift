import XCTest
import SwiftData
import UIKit
import AVFoundation
import Speech
@testable import Processly

final class ProcesslyUITests: XCTestCase {
    @MainActor
    func testHappyPathMockedFlow() async throws {
        let schema = Schema([SOP.self, UserPrefs.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context = container.mainContext
        let metrics = ConsoleMetricsService()
        let quotaService = QuotaService(metrics: metrics)
        let repo = SOPRepository(context: context)

        let mockSpeech = TranscriptMockService(mockTranscript: "Agenda and recap")
        try await mockSpeech.startRecording()
        XCTAssertEqual(mockSpeech.currentTranscription.fullText, "Agenda and recap")

        let response = LLMGenerationResponse(
            title: "Prep Meeting",
            summary: "Summarize",
            toolsNeeded: ["Slides"],
            steps: [
                .init(number: 1, instruction: "Gather agenda and dial in", notes: nil, estMinutes: 5),
                .init(number: 2, instruction: "Send recap", notes: "Include action items", estMinutes: 10)
            ],
            warnings: [],
            tags: ["meetings"]
        )

        let llm = MockLLMService(result: .success(response))
        let viewModel = GenerateViewModel()
        let metricsSpy = ConsoleMetricsService()
        viewModel.configure(
            job: GenerationJob(rawText: "Agenda and recap"),
            context: context,
            llmService: llm,
            metrics: metricsSpy,
            quotaService: quotaService
        )

        await viewModel.generate()

        guard case .success(let sop) = viewModel.state else {
            return XCTFail("Expected generated SOP")
        }

        XCTAssertEqual(sop.steps.count, 2)
        XCTAssertEqual(sop.tools.first, "Slides")

        XCTAssertTrue(try quotaService.canFinalize(using: context))
        sop.status = .final
        sop.updatedAt = .now
        try context.save()
        try quotaService.incrementFinalize(using: context)

        let exportService = ExportService(metrics: metrics)
        let pdfURL = try exportService.exportPDF(sop: sop, isPro: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
        try? FileManager.default.removeItem(at: pdfURL)
    }


    @MainActor
    func testFreeUserUpgradeUnlocksWatermarkFreeExport() throws {
        let schema = Schema([SOP.self, UserPrefs.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let metrics = ConsoleMetricsService()
        let quotaService = QuotaService(metrics: metrics)
        let exportService = ExportService(metrics: metrics)

        let prefs = UserPrefs(proActive: false)
        context.insert(prefs)
        try context.save()

        let sop = SOP(
            title: "Upgrade Flow",
            summary: "Summary",
            tags: ["ops"],
            tools: ["Checklist"],
            steps: [
                SOPStep(number: 1, instruction: "Draft", notes: nil, estMinutes: 5),
                SOPStep(number: 2, instruction: "Share", notes: "Send recap", estMinutes: 3)
            ],
            sourceRaw: "source",
            status: .draft
        )
        context.insert(sop)
        try context.save()

        for _ in 0..<AppConstants.freeQuota {
            XCTAssertTrue(try quotaService.canFinalize(using: context))
            try quotaService.incrementFinalize(using: context)
        }

        XCTAssertFalse(try quotaService.canFinalize(using: context))

        try quotaService.setProStatus(isActive: true, using: context)
        XCTAssertTrue(try quotaService.canFinalize(using: context))

        sop.status = .final
        sop.updatedAt = .now
        try context.save()
        try quotaService.incrementFinalize(using: context)

        let pdfURL = try exportService.exportPDF(sop: sop, isPro: true)
        defer { try? FileManager.default.removeItem(at: pdfURL) }
        let data = try Data(contentsOf: pdfURL)
        let dataString = String(data: data, encoding: .isoLatin1) ?? ""
        XCTAssertFalse(dataString.contains(Brand.watermarkFree))
    }

    func testSettingsDeepLinkShownWhenSpeechDenied() {
        XCTAssertTrue(SettingsView.shouldShowSettingsLink(microphonePermission: .granted, speechPermission: .denied))
        XCTAssertTrue(SettingsView.shouldShowSettingsLink(microphonePermission: .denied, speechPermission: .authorized))
        XCTAssertFalse(SettingsView.shouldShowSettingsLink(microphonePermission: .granted, speechPermission: .authorized))
    }

    func testSpeechDeniedErrorMessageContainsGuidance() {
        let error = SpeechError.microphoneDenied
        XCTAssertTrue(error.localizedDescription.contains("Microphone"))
    }

    func testBrandConstants() {
        XCTAssertEqual(Brand.name, "Processly")
        XCTAssertEqual(Brand.proName, "Processly Pro")
        XCTAssertEqual(Brand.watermarkFree, "Generated by Processly (Free)")
        XCTAssertEqual(Brand.tagline, "Turn messy notes into clear processes instantly")
        XCTAssertFalse(Brand.name.localizedCaseInsensitiveContains("SOPsmith"))
        XCTAssertFalse(Brand.proName.localizedCaseInsensitiveContains("SOPsmith"))
        XCTAssertFalse(Brand.watermarkFree.localizedCaseInsensitiveContains("SOPsmith"))
        XCTAssertFalse(Brand.tagline.localizedCaseInsensitiveContains("SOPsmith"))
    }

    @MainActor
    func testQuotaTriggersPaywallAfterLimit() throws {
        let container = try ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let quotaService = QuotaService(metrics: ConsoleMetricsService())
        let prefs = UserPrefs(proActive: false)
        context.insert(prefs)
        try context.save()

        for _ in 0..<5 {
            XCTAssertTrue(try quotaService.canFinalize(using: context))
            try quotaService.incrementFinalize(using: context)
        }

        XCTAssertFalse(try quotaService.canFinalize(using: context))
    }

    func test_accessibilityLabelsExist() {
        let homeApp = launchApp(with: ["--ui-testing"])
        assertElementExists(homeApp.buttons["home.record"])
        assertElementExists(homeApp.buttons["home.paste"])
        XCTAssertTrue(homeApp.otherElements["home.recent"].exists)

        homeApp.buttons["home.record"].tap()
        assertElementExists(homeApp.buttons["capture.record"])
        XCTAssertTrue(homeApp.buttons["capture.generate"].exists)
        tapBack(in: homeApp)
        homeApp.terminate()

        let paywallApp = launchApp(with: ["--ui-testing", "--ui-show-paywall"])
        assertElementExists(paywallApp.buttons["paywall.close"])
        XCTAssertTrue(paywallApp.buttons["paywall.restore"].exists)
        paywallApp.terminate()

        let exportApp = launchApp(with: ["--ui-testing", "--ui-show-export"])
        assertElementExists(exportApp.buttons["export.cta"])
        exportApp.buttons["export.cta"].tap()
        XCTAssertTrue(exportApp.otherElements["export.preview"].waitForExistence(timeout: 5))
        exportApp.terminate()
    }

    func test_dynamicTypeDoesNotClip() {
        let category = UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
        let homeApp = launchApp(with: ["--ui-testing", "-UIPreferredContentSizeCategoryName", category])
        assertElementIsHittable(homeApp.buttons["home.record"])
        homeApp.buttons["home.record"].tap()
        assertElementIsHittable(homeApp.buttons["capture.record"])
        tapBack(in: homeApp)
        assertElementIsHittable(homeApp.buttons["home.paste"])
        homeApp.buttons["home.paste"].tap()
        tapBack(in: homeApp)
        homeApp.terminate()

        let paywallApp = launchApp(with: ["--ui-testing", "--ui-show-paywall", "-UIPreferredContentSizeCategoryName", category])
        assertElementIsHittable(paywallApp.buttons["paywall.close"])
        assertElementIsHittable(paywallApp.buttons["paywall.restore"])
        paywallApp.terminate()

        let exportApp = launchApp(with: ["--ui-testing", "--ui-show-export", "-UIPreferredContentSizeCategoryName", category])
        let exportButton = exportApp.buttons["export.cta"]
        assertElementIsHittable(exportButton)
        exportButton.tap()
        XCTAssertTrue(exportApp.otherElements["export.preview"].waitForExistence(timeout: 5))
        exportApp.terminate()
    }
    
    func test_freeQuotaThenPaywallPurchaseThenExport() {
        // Given
        let app = launchApp(with: ["--ui-testing"])
        
        // Create 5 processes and finalize them to exhaust free quota
        for i in 1...5 {
            createAndFinalizeProcess(number: i, in: app)
        }
        
        // Attempt 6th process - should trigger paywall
        app.buttons["home.record"].tap()
        app.buttons["capture.record"].tap()
        sleep(2) // Record for 2 seconds
        app.buttons["capture.record"].tap() // Stop recording
        app.buttons["capture.generate"].tap()
        
        // Wait for generation to complete
        XCTAssertTrue(app.staticTexts["generate.success_prefix"].waitForExistence(timeout: 10))
        app.buttons["generate.continue_edit"].tap()
        
        // Attempt to finalize - should show paywall
        app.buttons["edit.finalize"].tap()
        XCTAssertTrue(app.staticTexts["finalize.quota.blocked"].waitForExistence(timeout: 5))
        app.buttons["finalize.paywall"].tap()
        
        // Verify paywall is shown
        XCTAssertTrue(app.staticTexts["Upgrade to Pro"].exists)
        XCTAssertTrue(app.buttons["paywall.buy.monthly"].exists)
        
        // Mock purchase success
        app.buttons["paywall.buy.monthly"].tap()
        XCTAssertTrue(app.staticTexts["Purchase successful!"].waitForExistence(timeout: 5))
        
        // Close paywall
        app.buttons["paywall.close"].tap()
        
        // Now should be able to finalize
        app.buttons["finalize.cta"].tap()
        XCTAssertTrue(app.staticTexts["finalize.toast.success"].waitForExistence(timeout: 5))
        
        // Navigate to export
        app.buttons["export.cta"].tap()
        
        // Verify export options are available
        XCTAssertTrue(app.buttons["export.format.pdf"].exists)
        XCTAssertTrue(app.buttons["export.format.docx"].exists)
        XCTAssertTrue(app.buttons["export.format.markdown"].exists)
        
        // Export PDF and verify no watermark
        app.buttons["export.format.pdf"].tap()
        app.buttons["export.export"].tap()
        
        // Verify export preview shows no watermark
        XCTAssertTrue(app.staticTexts["Export Preview"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Generated with Processly (Free)"].exists)
    }
    
    private func createAndFinalizeProcess(number: Int, in app: XCUIApplication) {
        // Start recording
        app.buttons["home.record"].tap()
        app.buttons["capture.record"].tap()
        sleep(2) // Record for 2 seconds
        app.buttons["capture.record"].tap() // Stop recording
        
        // Generate process
        app.buttons["capture.generate"].tap()
        XCTAssertTrue(app.staticTexts["generate.success_prefix"].waitForExistence(timeout: 10))
        app.buttons["generate.continue_edit"].tap()
        
        // Finalize process
        app.buttons["edit.finalize"].tap()
        app.buttons["finalize.cta"].tap()
        XCTAssertTrue(app.staticTexts["finalize.toast.success"].waitForExistence(timeout: 5))
        
        // Return to home
        app.buttons["export.cta"].tap() // This should navigate back to home
    }
}

private struct MockLLMService: LLMService {
    let result: Result<SOPDTO, LLMError>

    func request(
        rawText: String,
        titleHint: String?,
        includeTools: Bool,
        maxSteps: Int,
        tone: String
    ) async -> Result<SOPDTO, LLMError> {
        result
    }

    func generateSOP(from request: LLMGenerationRequest) async throws -> LLMGenerationResponse {
        switch result {
        case .success(let dto):
            return dto
        case .failure(let error):
            throw error
        }
    }
}

private extension ProcesslyUITests {
    func launchApp(with arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    func assertElementExists(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
    }

    func assertElementIsHittable(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        XCTAssertTrue(element.isHittable)
    }

    func tapBack(in app: XCUIApplication) {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.waitForExistence(timeout: 2) {
            backButton.tap()
        }
    }
}
