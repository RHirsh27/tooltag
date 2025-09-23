import XCTest
import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
@testable import Processly

final class MetricsServiceTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        MetricsService.enabled = true
    }

    func testAppLaunchPrintsWhenEnabled() {
        MetricsService.enabled = true
        let output = captureOutput {
            MetricsService.appLaunch()
        }
        XCTAssertTrue(output.contains("Metrics: app_launch {}"))
    }

    func testAppLaunchDoesNotPrintWhenDisabled() {
        MetricsService.enabled = false
        let output = captureOutput {
            MetricsService.appLaunch()
        }
        XCTAssertTrue(output.isEmpty)
    }

    func testFirstFinalizePrintsProperties() {
        MetricsService.enabled = true
        let output = captureOutput {
            MetricsService.firstFinalize(deltaSeconds: 42)
        }
        XCTAssertTrue(output.contains("Metrics: first_finalize"))
        XCTAssertTrue(output.contains("deltaSeconds: 42"))
    }

    func testGenLatencyPrintsPercentiles() {
        MetricsService.enabled = true
        let output = captureOutput {
            MetricsService.genLatency(p50: 12.3, p90: 45.6)
        }
        XCTAssertTrue(output.contains("Metrics: gen_latency"))
        XCTAssertTrue(output.contains("p50: 12.3"))
        XCTAssertTrue(output.contains("p90: 45.6"))
    }

    private func captureOutput(_ work: () -> Void) -> String {
        let pipe = Pipe()
        let original = dup(fileno(stdout))
        fflush(stdout)
        dup2(pipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        work()
        fflush(stdout)
        dup2(original, fileno(stdout))
        close(original)
        pipe.fileHandleForWriting.closeFile()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        pipe.fileHandleForReading.closeFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
