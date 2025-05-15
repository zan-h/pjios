import XCTest
@testable import phonejailOS

final class LLMServiceTests: XCTestCase {
    var sut: LLMService!
    var mockSession: MockURLSession!
    
    override func setUpWithError() throws {
        mockSession = MockURLSession()
        sut = LLMService(session: mockSession)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockSession = nil
    }
    
    func testInitialStatus() {
        XCTAssertEqual(sut.status, .idle)
    }
    
    func testGenerateResponseSuccess() async throws {
        // Given
        let message = Message(content: "Can I use Instagram?", sender: .user)
        let personality = Personality.strict
        let context: [Message] = []
        
        let mockResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "I'm sorry, but Instagram is currently blocked."
                    }
                }
            ]
        }
        """
        mockSession.mockData = mockResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let response = try await sut.generateResponse(
            message: message,
            personality: personality,
            context: context
        )
        
        // Then
        XCTAssertEqual(response, "I'm sorry, but Instagram is currently blocked.")
        XCTAssertEqual(sut.status, .idle)
    }
    
    func testGenerateResponseUnauthorized() async {
        // Given
        let message = Message(content: "Can I use Instagram?", sender: .user)
        let personality = Personality.strict
        let context: [Message] = []
        
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await sut.generateResponse(
                message: message,
                personality: personality,
                context: context
            )
            XCTFail("Expected unauthorized error")
        } catch LLMError.unauthorized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateResponseRateLimit() async {
        // Given
        let message = Message(content: "Can I use Instagram?", sender: .user)
        let personality = Personality.strict
        let context: [Message] = []
        
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await sut.generateResponse(
                message: message,
                personality: personality,
                context: context
            )
            XCTFail("Expected rate limit error")
        } catch LLMError.rateLimitExceeded {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateResponseWithAppContext() async throws {
        // Given
        let appContext = AppContext(
            appName: "Instagram",
            category: .social,
            blockReason: "Excessive usage",
            unblockDuration: 3600
        )
        let message = Message(
            content: "Can I use Instagram?",
            sender: .user,
            appContext: appContext
        )
        let personality = Personality.strict
        let context: [Message] = []
        
        let mockResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "I see you want to use Instagram. Given your previous excessive usage, I'll need a good reason."
                    }
                }
            ]
        }
        """
        mockSession.mockData = mockResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let response = try await sut.generateResponse(
            message: message,
            personality: personality,
            context: context
        )
        
        // Then
        XCTAssertEqual(response, "I see you want to use Instagram. Given your previous excessive usage, I'll need a good reason.")
        XCTAssertEqual(sut.status, .idle)
    }
}

// MARK: - Mock URLSession
class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse else {
            throw LLMError.networkError
        }
        
        return (mockData ?? Data(), response)
    }
} 