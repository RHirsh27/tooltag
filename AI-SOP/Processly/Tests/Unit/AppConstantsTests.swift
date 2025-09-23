import XCTest
@testable import Processly

final class AppConstantsTests: XCTestCase {
    func testPrivacyPolicyURL() {
        XCTAssertEqual(AppConstants.LegalLinks.privacyPolicy.absoluteString, "https://processly.app/privacy")
    }

    func testTermsOfServiceURL() {
        XCTAssertEqual(AppConstants.LegalLinks.termsOfService.absoluteString, "https://processly.app/terms")
    }
}
