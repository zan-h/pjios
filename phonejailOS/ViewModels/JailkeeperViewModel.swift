import Foundation
import SwiftUI

@MainActor
class JailkeeperViewModel: ObservableObject {
    @Published private(set) var jailkeeper: Jailkeeper
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let llmService: LLMService
    
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
            let response = try await llmService.generateResponse(
                message: userMessage,
                personality: jailkeeper.personality,
                context: jailkeeper.messages
            )
            let assistantMessage = Message(content: response, sender: .jailkeeper)
            jailkeeper.messages.append(assistantMessage)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func updatePersonality(_ personality: Personality) {
        jailkeeper.personality = personality
    }
    
    func clearMessages() {
        jailkeeper.messages.removeAll()
    }
    
    func clearError() {
        error = nil
    }
}
