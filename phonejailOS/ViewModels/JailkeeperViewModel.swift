import Foundation
import SwiftUI

@MainActor
class JailkeeperViewModel: ObservableObject {
    @Published private(set) var jailkeeper: Jailkeeper
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var isInAccessControlMode: Bool = false
    @Published private(set) var accessControlService: AccessControlService?
    @Published var currentMode: JailkeeperMode {
        didSet {
            jailkeeper.switchMode(to: currentMode)
            if currentMode == .guide {
                exitAccessControlMode()
            }
        }
    }
    @Published var currentTheme: ConversationTheme? {
        didSet {
            if let theme = currentTheme {
                jailkeeper.setTheme(theme)
            }
        }
    }
    
    private let llmService: LLMService
    private let accessCodeword = "SCHEMA_ACCESS_GRANTED_2025" // Secret codeword for access
    
    init(llmService: LLMService) {
        self.llmService = llmService
        self.jailkeeper = Jailkeeper(personality: .balanced, mode: .guide)
        self.currentMode = .guide
        self.currentTheme = nil
        
        // Add welcome message for guide mode
        addWelcomeMessage()
    }
    
    static func create() async -> JailkeeperViewModel {
        let llmService = await LLMService()
        return JailkeeperViewModel(llmService: llmService)
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = Message(
            content: "👋 Hello! I'm your digital wellness companion. I'm here to help you develop a healthier relationship with technology using proven therapeutic techniques. How are you feeling about your digital habits today?",
            sender: .jailkeeper,
            theme: .dailyCheckin
        )
        jailkeeper.messages.append(welcomeMessage)
    }
    
    func sendMessage(_ content: String) async {
        let userMessage = Message(
            content: content, 
            sender: .user, 
            theme: currentTheme
        )
        jailkeeper.messages.append(userMessage)
        
        isLoading = true
        error = nil
        
        do {
            let response: String
            
            if currentMode == .authority && isInAccessControlMode {
                // Use access control system prompt
                response = try await llmService.generateAccessControlResponse(
                    message: userMessage,
                    personality: jailkeeper.personality,
                    context: jailkeeper.messages,
                    accessCodeword: accessCodeword
                )
            } else if currentMode == .guide {
                // Use therapeutic conversation
                response = try await llmService.generateTherapeuticResponse(
                    message: userMessage,
                    personality: jailkeeper.personality,
                    context: jailkeeper.messages,
                    theme: currentTheme,
                    progress: jailkeeper.therapeuticProgress
                )
            } else {
                // Fallback to normal conversation
                response = try await llmService.generateResponse(
                    message: userMessage,
                    personality: jailkeeper.personality,
                    context: jailkeeper.messages
                )
            }
            
            let assistantMessage = Message(
                content: response, 
                sender: .jailkeeper,
                theme: currentTheme
            )
            jailkeeper.messages.append(assistantMessage)
            
            // Check if the response contains the access codeword (authority mode only)
            if currentMode == .authority && isInAccessControlMode && response.contains(accessCodeword) {
                grantSchemaAccess()
            }
            
            // Extract insights and goals from therapeutic conversations
            if currentMode == .guide {
                extractTherapeuticInsights(from: response)
            }
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Mode Management
    
    func switchToGuideMode() {
        currentMode = .guide
        addModeTransitionMessage(to: .guide)
    }
    
    func switchToAuthorityMode() {
        currentMode = .authority
        addModeTransitionMessage(to: .authority)
    }
    
    private func addModeTransitionMessage(to mode: JailkeeperMode) {
        let message: String
        switch mode {
        case .guide:
            message = "🌱 I'm now in Guide Mode. Let's focus on your digital wellness journey. How can I support you today?"
        case .authority:
            message = "🔒 I'm now in Authority Mode. I'll help evaluate access requests when needed."
        }
        
        let transitionMessage = Message(
            content: message,
            sender: .system
        )
        jailkeeper.messages.append(transitionMessage)
    }
    
    // MARK: - Therapeutic Features
    
    func startDailyCheckin() async {
        currentTheme = .dailyCheckin
        isLoading = true
        
        do {
            let checkinMessage = try await llmService.generateDailyCheckin(
                personality: jailkeeper.personality,
                progress: jailkeeper.therapeuticProgress
            )
            
            let message = Message(
                content: checkinMessage,
                sender: .jailkeeper,
                theme: .dailyCheckin
            )
            jailkeeper.messages.append(message)
            jailkeeper.updateCheckinDate()
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func startWeeklyReview() async {
        currentTheme = .weeklyReview
        isLoading = true
        
        do {
            // TODO: Gather actual usage data
            let weeklyData: [String: Any] = [:]
            
            let reviewMessage = try await llmService.generateWeeklyReview(
                personality: jailkeeper.personality,
                progress: jailkeeper.therapeuticProgress,
                weeklyData: weeklyData
            )
            
            let message = Message(
                content: reviewMessage,
                sender: .jailkeeper,
                theme: .weeklyReview
            )
            jailkeeper.messages.append(message)
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func setConversationTheme(_ theme: ConversationTheme) {
        currentTheme = theme
        
        let themeMessage = Message(
            content: "💭 Let's focus on \(theme.description.lowercased()). What would you like to explore?",
            sender: .system,
            theme: theme
        )
        jailkeeper.messages.append(themeMessage)
    }
    
    func addGoal(_ goal: String) {
        jailkeeper.addGoal(goal)
        
        let goalMessage = Message(
            content: "🎯 New goal added: \(goal). I'll help you work towards this!",
            sender: .system,
            theme: .goalSetting
        )
        jailkeeper.messages.append(goalMessage)
    }
    
    func completeGoal(_ goal: String) {
        jailkeeper.completeGoal(goal)
        
        let completionMessage = Message(
            content: "🎉 Congratulations! You've completed your goal: \(goal). That's fantastic progress!",
            sender: .system,
            theme: .progressCelebration
        )
        jailkeeper.messages.append(completionMessage)
    }
    
    private func extractTherapeuticInsights(from response: String) {
        // Simple keyword-based insight extraction
        // In a real implementation, this could use NLP or structured prompts
        
        if response.lowercased().contains("insight") || response.lowercased().contains("realize") {
            // Extract potential insights for tracking
            // This is a simplified implementation
        }
        
        if response.lowercased().contains("goal") && response.lowercased().contains("set") {
            // Potential goal setting detected
        }
        
        if response.lowercased().contains("trigger") {
            // Trigger identification detected
        }
    }

    // MARK: - Access Control Methods
    
    func enterAccessControlMode() {
        currentMode = .authority
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
        if currentMode == .authority {
            currentMode = .guide
        }
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
        addWelcomeMessage()
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Computed Properties
    
    var therapeuticProgress: TherapeuticProgress {
        return jailkeeper.therapeuticProgress
    }
    
    var hasActiveGoals: Bool {
        return !jailkeeper.therapeuticProgress.currentGoals.isEmpty
    }
    
    var engagementStreak: Int {
        return jailkeeper.therapeuticProgress.engagementStreak
    }
}
