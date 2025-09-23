import XCTest
@testable import Processly

final class IAPServiceTests: XCTestCase {
    var service: IAPService!
    var mockMetrics: MockMetricsReporter!
    
    override func setUp() {
        super.setUp()
        mockMetrics = MockMetricsReporter()
        service = IAPService(metrics: mockMetrics)
    }
    
    func testPriceMappingFromProducts() async {
        // Given
        let mockProducts = [
            MockProduct(id: "pro_monthly_799", displayPrice: "$7.99"),
            MockProduct(id: "pro_yearly_4999", displayPrice: "$49.99")
        ]
        
        // When
        service.subscriptions = mockProducts
        service.prices = mockProducts.reduce(into: [:]) { result, product in
            result[product.id] = product.displayPrice
        }
        
        // Then
        XCTAssertEqual(service.prices["pro_monthly_799"], "$7.99")
        XCTAssertEqual(service.prices["pro_yearl_4999"], "$49.99")
    }
    
    func testEmptyProductsSetsStatusMessage() async {
        // Given
        service.subscriptions = []
        
        // When
        await service.loadProducts()
        
        // Then
        XCTAssertEqual(service.statusMessage, "Products unavailable. Please try again.")
    }
    
    func testPurchaseErrorMapping() {
        // Given
        let service = IAPService(metrics: mockMetrics)
        
        // When & Then
        let userCancelledError = NSError(domain: "StoreKit", code: 0, userInfo: nil)
        XCTAssertEqual(service.mapPurchaseError(userCancelledError), "Purchase cancelled.")
        
        let networkError = URLError(.notConnectedToInternet)
        XCTAssertEqual(service.mapPurchaseError(networkError), "No internet connection. Please check your network and try again.")
        
        let genericError = NSError(domain: "Test", code: 999, userInfo: nil)
        XCTAssertEqual(service.mapPurchaseError(genericError), "We couldn't complete the purchase. Please try again.")
    }
}

// MARK: - Mock Classes

struct MockProduct {
    let id: String
    let displayPrice: String
}
