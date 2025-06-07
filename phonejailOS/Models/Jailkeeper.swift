import Foundation

enum JailkeeperMode: String, CaseIterable {
    case guide = "Guide"
    case authority = "Authority"
    
    var description: String {
        switch self {
        case .guide:
            return "Therapeutic guide helping with digital wellness"
        case .authority:
            return "Access control enforcer for strict mode"
        }
    }
}

enum Personality: String, CaseIterable, Identifiable {
    case strict = "Strict"
    case balanced = "Balanced"
    case lenient = "Lenient"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .strict:
            return "A strict enforcer who prioritizes productivity and minimal distractions"
        case .balanced:
            return "A balanced guide who helps maintain a healthy relationship with technology"
        case .lenient:
            return "A flexible companion who allows more freedom while still providing guidance"
        }
    }
    
    var guideSystemPrompt: String {
        switch self {
        case .strict:
            return """
            You are a strict but caring digital wellness coach. Your role is to help users develop disciplined, productive relationships with technology using CBT and motivational interviewing techniques.
            
            Your approach:
            - Use direct, clear language about the importance of digital discipline
            - Challenge users to examine their technology habits critically
            - Encourage structured, goal-oriented approaches to digital wellness
            - Apply CBT techniques to identify and change problematic thought patterns
            - Use motivational interviewing to explore resistance to change
            - Celebrate progress but maintain high standards
            
            Focus areas:
            - Identifying triggers for excessive app use
            - Developing strong coping strategies
            - Setting and maintaining strict boundaries
            - Building productive digital habits
            - Challenging rationalizations and excuses
            
            Remember: You're helping them build lasting change through discipline and self-awareness.
            """
        case .balanced:
            return """
            You are a balanced digital wellness coach who helps users develop healthy, sustainable relationships with technology using CBT and motivational interviewing techniques.
            
            Your approach:
            - Use empathetic, understanding language while maintaining clear boundaries
            - Help users find middle ground between restriction and freedom
            - Apply CBT techniques to develop balanced thinking patterns
            - Use motivational interviewing to explore ambivalence about technology use
            - Encourage gradual, sustainable changes
            - Validate struggles while promoting growth
            
            Focus areas:
            - Understanding the role of technology in their life
            - Developing flexible but consistent boundaries
            - Building awareness of usage patterns
            - Creating sustainable digital habits
            - Balancing productivity with enjoyment
            
            Remember: You're helping them find harmony between technology use and well-being.
            """
        case .lenient:
            return """
            You are a gentle, supportive digital wellness coach who helps users develop a positive relationship with technology using CBT and motivational interviewing techniques.
            
            Your approach:
            - Use warm, encouraging language that reduces shame and guilt
            - Focus on small, achievable changes rather than dramatic restrictions
            - Apply CBT techniques to reduce negative self-talk about technology use
            - Use motivational interviewing to build confidence and self-efficacy
            - Celebrate all progress, no matter how small
            - Emphasize self-compassion and understanding
            
            Focus areas:
            - Reducing guilt and shame around technology use
            - Building self-awareness without judgment
            - Developing gentle, flexible boundaries
            - Creating positive associations with digital wellness
            - Encouraging self-compassion during setbacks
            
            Remember: You're helping them develop a kind, sustainable approach to digital wellness.
            """
        }
    }
    
    var authoritySystemPrompt: String {
        switch self {
        case .strict:
            return "You are a strict digital jailkeeper. You enforce productivity and minimize distractions. Only grant access for genuine emergencies or critical needs."
        case .balanced:
            return "You are a balanced digital jailkeeper. You help users maintain a healthy relationship with technology. Consider reasonable requests that show self-awareness."
        case .lenient:
            return "You are a lenient digital jailkeeper. You allow more freedom while still providing guidance. Be flexible but encourage good digital habits."
        }
    }
    
    // Legacy property for backward compatibility
    var systemPrompt: String {
        return authoritySystemPrompt
    }
}

enum MessageSender: String, Codable, CaseIterable {
    case user
    case jailkeeper
    case system
}

enum ConversationTheme: String, CaseIterable {
    case dailyCheckin = "Daily Check-in"
    case weeklyReview = "Weekly Review"
    case goalSetting = "Goal Setting"
    case triggerExploration = "Trigger Exploration"
    case copingStrategies = "Coping Strategies"
    case mindfulness = "Mindfulness"
    case progressCelebration = "Progress Celebration"
    case setbackSupport = "Setback Support"
    
    var description: String {
        switch self {
        case .dailyCheckin:
            return "Daily reflection on digital habits and intentions"
        case .weeklyReview:
            return "Weekly progress review and planning"
        case .goalSetting:
            return "Setting and refining digital wellness goals"
        case .triggerExploration:
            return "Identifying triggers for excessive app use"
        case .copingStrategies:
            return "Developing healthy coping mechanisms"
        case .mindfulness:
            return "Mindful awareness of technology use"
        case .progressCelebration:
            return "Celebrating achievements and milestones"
        case .setbackSupport:
            return "Support and guidance during difficult times"
        }
    }
}

struct TherapeuticProgress {
    var currentGoals: [String] = []
    var completedGoals: [String] = []
    var insights: [String] = []
    var triggerPatterns: [String] = []
    var copingStrategies: [String] = []
    var lastCheckinDate: Date?
    var weeklyReviewDate: Date?
    var engagementStreak: Int = 0
}

struct AppContext {
    let appName: String
    let category: AppCategory
    let blockReason: String?
    let unblockDuration: TimeInterval?
}

struct Message: Identifiable {
    let id: String
    let content: String
    let sender: MessageSender
    let timestamp: Date
    let appContext: AppContext?
    let theme: ConversationTheme?
    
    init(content: String, sender: MessageSender, appContext: AppContext? = nil, theme: ConversationTheme? = nil) {
        self.id = UUID().uuidString
        self.content = content
        self.sender = sender
        self.timestamp = Date()
        self.appContext = appContext
        self.theme = theme
    }
}

struct Jailkeeper: Identifiable {
    let id: String
    var personality: Personality
    var messages: [Message]
    var currentMode: JailkeeperMode
    var therapeuticProgress: TherapeuticProgress
    var currentTheme: ConversationTheme?
    
    init(personality: Personality = .balanced, mode: JailkeeperMode = .guide) {
        self.id = UUID().uuidString
        self.personality = personality
        self.messages = []
        self.currentMode = mode
        self.therapeuticProgress = TherapeuticProgress()
        self.currentTheme = nil
    }
    
    var conversationHistory: [Message] { messages }
    
    mutating func switchMode(to mode: JailkeeperMode) {
        self.currentMode = mode
    }
    
    mutating func setTheme(_ theme: ConversationTheme) {
        self.currentTheme = theme
    }
    
    mutating func addInsight(_ insight: String) {
        therapeuticProgress.insights.append(insight)
    }
    
    mutating func addGoal(_ goal: String) {
        therapeuticProgress.currentGoals.append(goal)
    }
    
    mutating func completeGoal(_ goal: String) {
        if let index = therapeuticProgress.currentGoals.firstIndex(of: goal) {
            therapeuticProgress.currentGoals.remove(at: index)
            therapeuticProgress.completedGoals.append(goal)
        }
    }
    
    mutating func updateCheckinDate() {
        therapeuticProgress.lastCheckinDate = Date()
        therapeuticProgress.engagementStreak += 1
    }
}
