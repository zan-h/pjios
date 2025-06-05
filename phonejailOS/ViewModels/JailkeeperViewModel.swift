import Foundation
import SwiftUI

@MainActor
class JailkeeperViewModel: ObservableObject {
    @Published private(set) var jailkeeper: Jailkeeper
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var isInAccessControlMode: Bool = false
    @Published private(set) var accessControlService: AccessControlService?
    
    private let llmService: LLMService
    private let accessCodeword = "SCHEMA_ACCESS_GRANTED_2025" // Secret codeword for access
    
    init(llmService: LLMService) {
        self.llmService = llmService
        self.jailkeeper = Jailkeeper(personality: .balanced)
    }
    
    static func create() async -> JailkeeperViewModel {
        let llmService = await LLMService()
        return JailkeeperViewModel(llmService: llmService)
    }
    
    func sendMessage(_ content: String) async {
        let userMessage = Message(content: content, sender: .user)
        jailkeeper.messages.append(userMessage)
        
        isLoading = true
        error = nil
        
        do {
            let response: String
            
            if isInAccessControlMode {
                // Use access control system prompt
                response = try await llmService.generateAccessControlResponse(
                    message: userMessage,
                    personality: jailkeeper.personality,
                    context: jailkeeper.messages,
                    accessCodeword: accessCodeword
                )
            } else {
                // Use normal conversation
                response = try await llmService.generateResponse(
                    message: userMessage,
                    personality: jailkeeper.personality,
                    context: jailkeeper.messages
                )
            }
            
            let assistantMessage = Message(content: response, sender: .jailkeeper)
            jailkeeper.messages.append(assistantMessage)
            
            // Check if the response contains the access codeword
            if isInAccessControlMode && response.contains(accessCodeword) {
                grantSchemaAccess()
            }
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Access Control Methods
    
    func enterAccessControlMode() {
        isInAccessControlMode = true
        
        // Add a system message to set the context
        let systemMessage = Message(
            content: "🔒 You are now in Access Control Mode. The user needs to convince you to grant them access to modify their blocking schemas. Evaluate their request based on your personality and only grant access if you're truly convinced they have a valid reason.",
            sender: .system
        )
        jailkeeper.messages.append(systemMessage)
    }
    
    func exitAccessControlMode() {
        isInAccessControlMode = false
        accessControlService = nil
    }
    
    func setAccessControlService(_ service: AccessControlService) {
        self.accessControlService = service
    }
    
    private func grantSchemaAccess() {
        guard let accessControlService = accessControlService else {
            print("⚠️ AccessControlService not set")
            return
        }
        
        let duration = getDurationBasedOnPersonality()
        accessControlService.grantTemporaryAccess(duration: duration)
        
        // Exit access control mode after granting access
        exitAccessControlMode()
        
        // Add a confirmation message
        let confirmationMessage = Message(
            content: "✅ Access granted! You now have \(Int(duration/60)) minutes of temporary access to modify your schemas. Use this time wisely.",
            sender: .system
        )
        jailkeeper.messages.append(confirmationMessage)
        
        print("🔓 Schema access granted for \(Int(duration/60)) minutes")
    }
    
    private func getDurationBasedOnPersonality() -> TimeInterval {
        switch jailkeeper.personality {
        case .strict:
            return 5 * 60 // 5 minutes
        case .balanced:
            return 10 * 60 // 10 minutes
        case .lenient:
            return 15 * 60 // 15 minutes
        }
    }
    
    // MARK: - Legacy Methods (keeping for compatibility)
    
    func requestSchemaAccess(reason: String, accessControlService: AccessControlService) async -> Bool {
        // This method is now deprecated in favor of the conversational approach
        // But keeping it for backward compatibility
        return false
    }
    
    func updatePersonality(_ personality: Personality) {
        jailkeeper.personality = personality
    }
    
    func clearMessages() {
        jailkeeper.messages.removeAll()
        exitAccessControlMode()
    }
    
    func clearError() {
        error = nil
    }
}
