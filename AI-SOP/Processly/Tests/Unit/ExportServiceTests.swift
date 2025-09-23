import XCTest
@testable import Processly

final class ExportServiceTests: XCTestCase {
    var service: ExportService!
    var mockMetrics: MockMetricsReporter!
    
    override func setUp() {
        super.setUp()
        mockMetrics = MockMetricsReporter()
        service = ExportService(metrics: mockMetrics)
    }
    
    func testFreeTierIncludesWatermark() async {
        // Given
        let sop = createSampleSOP()
        let isPro = false
        
        // When
        let result = await service.export(
            sop: sop,
            format: .pdf,
            includeWatermark: !isPro
        )
        
        // Then
        switch result {
        case .success(let url):
            // Verify watermark is included in the exported file
            let content = try? String(contentsOf: url)
            XCTAssertTrue(content?.contains("Generated with Processly (Free)") == true)
        case .failure:
            XCTFail("Export should succeed")
        }
    }
    
    func testProTierExcludesWatermark() async {
        // Given
        let sop = createSampleSOP()
        let isPro = true
        
        // When
        let result = await service.export(
            sop: sop,
            format: .pdf,
            includeWatermark: !isPro
        )
        
        // Then
        switch result {
        case .success(let url):
            // Verify watermark is not included in the exported file
            let content = try? String(contentsOf: url)
            XCTAssertFalse(content?.contains("Generated with Processly (Free)") == true)
        case .failure:
            XCTFail("Export should succeed")
        }
    }
    
    func testAllFormatsSupported() async {
        // Given
        let sop = createSampleSOP()
        let formats: [ExportFormat] = [.pdf, .docx, .markdown]
        
        for format in formats {
            // When
            let result = await service.export(
                sop: sop,
                format: format,
                includeWatermark: false
            )
            
            // Then
            switch result {
            case .success(let url):
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            case .failure:
                XCTFail("Export should succeed for format \(format)")
            }
        }
    }
    
    private func createSampleSOP() -> SOP {
        let steps = [
            SOPStep(number: 1, instruction: "Test step 1"),
            SOPStep(number: 2, instruction: "Test step 2")
        ]
        
        return SOP(
            title: "Test SOP",
            summary: "A test SOP for unit testing",
            tools: ["Test Tool"],
            steps: steps,
            sourceRaw: "Test raw text",
            status: .final
        )
    }
}