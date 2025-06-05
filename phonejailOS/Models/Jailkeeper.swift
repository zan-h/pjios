import Foundation

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
    
    var systemPrompt: String {
        switch self {
        case .strict:
            return "You are a strict digital jailkeeper. You enforce productivity and minimize distractions."
        case .balanced:
            return "You are a balanced digital jailkeeper. You help users maintain a healthy relationship with technology."
        case .lenient:
            return "You are a lenient digital jailkeeper. You allow more freedom but still provide guidance."
        }
    }
}

enum MessageSender: String, Codable, CaseIterable {
    case user
    case jailkeeper
    case system
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
    
    init(content: String, sender: MessageSender, appContext: AppContext? = nil) {
        self.id = UUID().uuidString
        self.content = content
        self.sender = sender
        self.timestamp = Date()
        self.appContext = appContext
    }
}

struct Jailkeeper: Identifiable {
    let id: String
    var personality: Personality
    var messages: [Message]
    
    init(personality: Personality = .balanced) {
        self.id = UUID().uuidString
        self.personality = personality
        self.messages = []
    }
    
    var conversationHistory: [Message] { messages }
}
