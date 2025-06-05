import Foundation
import Combine

enum LLMError: LocalizedError {
    case invalidResponse
    case rateLimitExceeded
    case networkError
    case invalidRequest
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received invalid response from LLM service"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .networkError:
            return "Network error occurred"
        case .invalidRequest:
            return "Invalid request to LLM service"
        case .unauthorized:
            return "Unauthorized access to LLM service"
        }
    }
}

enum LLMServiceStatus {
    case idle
    case processing
    case error(Error)
}

@MainActor
class LLMService: ObservableObject {
    @Published private(set) var status: LLMServiceStatus = .idle
    
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession
    private var retryCount = 0
    private let maxRetries = 3
    
    // Helper function to load API Key from Info.plist
    private static func loadApiKeyFromInfoPlist() -> String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "LLM_API_KEY") as? String,
              !key.isEmpty,
              key != "YOUR_ACTUAL_OPENAI_API_KEY_HERE" else { // Ensure this placeholder matches if you have one
            let plistKeyExists = Bundle.main.object(forInfoDictionaryKey: "LLM_API_KEY") != nil
            print("LLMService Error: API Key missing, empty, or placeholder in Info.plist.")
            print("LLM_API_KEY found in Info.plist: \(plistKeyExists)")
            if let loadedKey = Bundle.main.object(forInfoDictionaryKey: "LLM_API_KEY") as? String {
                print("Loaded key value: '\(loadedKey)'")
            }
            // In a real app, you might want to throw an error or disable functionality
            // Forcing a crash in debug or returning a clearly invalid key might be preferable to silent failure.
            fatalError("CRITICAL: OpenAI API Key not configured correctly. Check Info.plist and Secrets.xcconfig.")
        }
        print("LLMService: Successfully loaded API Key.")
        return key
    }
    
    init(baseURL: URL = URL(string: "https://api.openai.com/v1/chat/completions")!,
         session: URLSession = .shared) {
        self.apiKey = LLMService.loadApiKeyFromInfoPlist()
        self.baseURL = baseURL
        self.session = session
    }
    
    func generateResponse(message: Message, personality: Personality, context: [Message]) async throws -> String {
        status = .processing
        
        do {
            let prompt = buildPrompt(message: message, personality: personality, context: context)
            let request = try createRequest(prompt: prompt)
            
            // Debug print statements
            print("--- LLMService Request ---")
            print("Attempting to call OpenAI with API Key (first 5 chars): \(String(self.apiKey.prefix(5)))")
            print("Request URL: \(request.url?.absoluteString ?? "No URL")")
            print("Prompt being sent: \(prompt)") // Be careful logging full prompts if they contain sensitive user data in production
            print("-------------------------")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let result = try parseResponse(data)
                status = .idle
                retryCount = 0
                return result
            case 401:
                throw LLMError.unauthorized
            case 429:
                throw LLMError.rateLimitExceeded
            default:
                throw LLMError.networkError
            }
        } catch {
            status = .error(error)
            
            // Implement retry logic for certain errors
            if shouldRetry(error) && retryCount < maxRetries {
                retryCount += 1
                return try await generateResponse(message: message, personality: personality, context: context)
            }
            
            throw error
        }
    }
    
    // MARK: - Access Control Methods
    
    func generateAccessControlResponse(message: Message, personality: Personality, context: [Message], accessCodeword: String) async throws -> String {
        status = .processing
        
        do {
            let prompt = buildAccessControlPrompt(message: message, personality: personality, context: context, accessCodeword: accessCodeword)
            let request = try createRequest(prompt: prompt)
            
            print("--- LLMService Access Control ---")
            print("Generating access control response with personality: \(personality.rawValue)")
            print("Access codeword included in system prompt")
            print("--------------------------------")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let result = try parseResponse(data)
                status = .idle
                retryCount = 0
                return result
            case 401:
                throw LLMError.unauthorized
            case 429:
                throw LLMError.rateLimitExceeded
            default:
                throw LLMError.networkError
            }
        } catch {
            status = .error(error)
            
            if shouldRetry(error) && retryCount < maxRetries {
                retryCount += 1
                return try await generateAccessControlResponse(message: message, personality: personality, context: context, accessCodeword: accessCodeword)
            }
            
            throw error
        }
    }
    
    func evaluateAccessRequest(request: String, personality: Personality, context: [Message]) async throws -> String {
        status = .processing
        
        do {
            let urlRequest = try createAccessEvaluationRequest(prompt: request)
            
            print("--- LLMService Access Evaluation ---")
            print("Evaluating access request with personality: \(personality.rawValue)")
            print("Request prompt: \(request)")
            print("-----------------------------------")
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let result = try parseResponse(data)
                status = .idle
                retryCount = 0
                return result
            case 401:
                throw LLMError.unauthorized
            case 429:
                throw LLMError.rateLimitExceeded
            default:
                throw LLMError.networkError
            }
        } catch {
            status = .error(error)
            
            if shouldRetry(error) && retryCount < maxRetries {
                retryCount += 1
                return try await evaluateAccessRequest(request: request, personality: personality, context: context)
            }
            
            throw error
        }
    }
    
    private func createAccessEvaluationRequest(prompt: String) throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": prompt]
            ],
            "temperature": 0.3, // Lower temperature for more consistent access decisions
            "max_tokens": 200
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func buildPrompt(message: Message, personality: Personality, context: [Message]) -> String {
        var prompt = personality.systemPrompt + "\n\n"
        
        // Add context from recent messages
        for contextMessage in context {
            prompt += "\(contextMessage.sender.rawValue.capitalized): \(contextMessage.content)\n"
        }
        
        // Add current message
        prompt += "\nUser: \(message.content)\n"
        
        // Add app context if available
        if let appContext = message.appContext {
            prompt += "\nApp Context:\n"
            prompt += "- Name: \(appContext.appName)\n"
            prompt += "- Category: \(appContext.category.rawValue)\n"
            if let reason = appContext.blockReason {
                prompt += "- Block Reason: \(reason)\n"
            }
            if let duration = appContext.unblockDuration {
                prompt += "- Requested Duration: \(formatDuration(duration))\n"
            }
        }
        
        prompt += "\nJailkeeper:"
        return prompt
    }
    
    private func createRequest(prompt: String) throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 150
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func parseResponse(_ data: Data) throws -> String {
        struct Response: Codable {
            struct Choice: Codable {
                let message: Message
            }
            struct Message: Codable {
                let content: String
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard let firstChoice = response.choices.first else {
            throw LLMError.invalidResponse
        }
        
        return firstChoice.message.content
    }
    
    private func shouldRetry(_ error: Error) -> Bool {
        switch error {
        case LLMError.networkError, LLMError.rateLimitExceeded:
            return true
        default:
            return false
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    private func buildAccessControlPrompt(message: Message, personality: Personality, context: [Message], accessCodeword: String) -> String {
        var prompt = """
        \(personality.systemPrompt)
        
        IMPORTANT: You are currently in ACCESS CONTROL MODE. The user is requesting access to modify their blocking schemas while strict mode is active.
        
        Your role is to evaluate their request based on your personality:
        - Strict: Only grant access for genuine emergencies or critical needs
        - Balanced: Consider reasonable requests that show self-awareness and valid reasons
        - Lenient: Be more flexible but still encourage good digital habits
        
        CRITICAL INSTRUCTION: If you decide to grant access, you MUST include the exact phrase "\(accessCodeword)" somewhere in your response. This is the secret code that unlocks schema access. Do NOT include this phrase unless you are genuinely convinced they should have access.
        
        Conversation history:
        """
        
        // Add context from recent messages (excluding system messages)
        for contextMessage in context.filter({ $0.sender != .system }) {
            prompt += "\n\(contextMessage.sender.rawValue.capitalized): \(contextMessage.content)"
        }
        
        // Add current message
        prompt += "\nUser: \(message.content)"
        
        // Add app context if available
        if let appContext = message.appContext {
            prompt += "\n\nApp Context:"
            prompt += "\n- Name: \(appContext.appName)"
            prompt += "\n- Category: \(appContext.category.rawValue)"
            if let reason = appContext.blockReason {
                prompt += "\n- Block Reason: \(reason)"
            }
            if let duration = appContext.unblockDuration {
                prompt += "\n- Requested Duration: \(formatDuration(duration))"
            }
        }
        
        prompt += "\n\nJailkeeper:"
        return prompt
    }
}
