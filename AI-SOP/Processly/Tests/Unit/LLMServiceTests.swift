import XCTest
@testable import Processly

final class LLMServiceTests: XCTestCase {
    var service: DefaultLLMService!
    var mockMetrics: MockMetricsReporter!
    
    override func setUp() {
        super.setUp()
        mockMetrics = MockMetricsReporter()
        service = DefaultLLMService(metrics: mockMetrics)
    }
    
    func testNoAPIKeyReturnsCorrectError() async {
        // Given
        service = DefaultLLMService(
            metrics: mockMetrics,
            apiKeyProvider: { nil }
        )
        
        // When
        let result = await service.request(
            rawText: "Test process",
            titleHint: nil,
            includeTools: true,
            maxSteps: 5,
            tone: "clear"
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .noAPIKey)
        }
    }
    
    func testRateLimitedLocalAfterMaxRequests() async {
        // Given
        service = DefaultLLMService(
            metrics: mockMetrics,
            apiKeyProvider: { "test-key" }
        )
        
        // When - Make 6 requests (more than the 5 request limit)
        var results: [Result<SOPDTO, LLMError>] = []
        for _ in 0..<6 {
            let result = await service.request(
                rawText: "Test process",
                titleHint: nil,
                includeTools: true,
                maxSteps: 5,
                tone: "clear"
            )
            results.append(result)
        }
        
        // Then
        let lastResult = results.last!
        switch lastResult {
        case .success:
            XCTFail("Expected rate limit error")
        case .failure(let error):
            XCTAssertEqual(error, .rateLimitedLocal)
        }
    }
    
    func testRetryCapsAfterTransient5xx() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.mockResponse = MockHTTPResponse(statusCode: 500, data: Data())
        
        service = DefaultLLMService(
            metrics: mockMetrics,
            apiKeyProvider: { "test-key" },
            session: mockSession
        )
        
        // When
        let result = await service.request(
            rawText: "Test process",
            titleHint: nil,
            includeTools: true,
            maxSteps: 5,
            tone: "clear"
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure after retries")
        case .failure(let error):
            XCTAssertEqual(error, .server(500))
        }
        
        // Verify retry attempts (should be 3)
        XCTAssertEqual(mockSession.requestCount, 3)
    }
}

// MARK: - Mock Classes

class MockMetricsReporter: MetricsReporter {
    func track(event: MetricsEvent) {}
    func track(event: MetricsEvent, properties: [String: Any]?) {}
}

class MockURLSession: URLSession {
    var mockResponse: MockHTTPResponse?
    var requestCount = 0
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requestCount += 1
        guard let mockResponse = mockResponse else {
            throw URLError(.notConnectedToInternet)
        }
        return (mockResponse.data, mockResponse.urlResponse)
    }
}

struct MockHTTPResponse {
    let statusCode: Int
    let data: Data
    let urlResponse: URLResponse
    
    init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
        self.urlResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}