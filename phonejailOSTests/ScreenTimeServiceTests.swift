import XCTest
@testable import phonejailOS

final class ScreenTimeServiceTests: XCTestCase {
    var sut: ScreenTimeService!
    
    override func setUpWithError() throws {
        sut = ScreenTimeService()
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }
    
    func testInitialAuthorizationStatus() {
        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
    }
    
    func testFetchInstalledAppsWithoutAuthorization() async {
        do {
            _ = try await sut.fetchInstalledApps()
            XCTFail("Expected error when fetching apps without authorization")
        } catch ScreenTimeError.notAuthorized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testBlockAppWithoutAuthorization() async {
        do {
            try await sut.blockApp(bundleIdentifier: "com.example.app")
            XCTFail("Expected error when blocking app without authorization")
        } catch ScreenTimeError.notAuthorized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUnblockAppWithoutAuthorization() async {
        do {
            try await sut.unblockApp(bundleIdentifier: "com.example.app")
            XCTFail("Expected error when unblocking app without authorization")
        } catch ScreenTimeError.notAuthorized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // Note: The following tests require actual ScreenTime authorization
    // and should be run on a real device with proper permissions
    
    /*
    func testFetchInstalledAppsWithAuthorization() async throws {
        // Request authorization first
        await sut.requestAuthorization()
        
        // Fetch apps
        let apps = try await sut.fetchInstalledApps()
        XCTAssertFalse(apps.isEmpty)
    }
    
    func testBlockAndUnblockApp() async throws {
        // Request authorization first
        await sut.requestAuthorization()
        
        let bundleIdentifier = "com.example.app"
        
        // Block app
        try await sut.blockApp(bundleIdentifier: bundleIdentifier)
        
        // Unblock app
        try await sut.unblockApp(bundleIdentifier: bundleIdentifier)
    }
    */
} 