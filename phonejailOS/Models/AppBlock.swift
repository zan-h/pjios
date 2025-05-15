import Foundation

enum AppCategory: String, CaseIterable, Identifiable {
    case social = "Social"
    case productivity = "Productivity"
    case entertainment = "Entertainment"
    case games = "Games"
    case utilities = "Utilities"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .social: return "person.2.fill"
        case .productivity: return "checkmark.seal"
        case .entertainment: return "film"
        case .games: return "gamecontroller"
        case .utilities: return "wrench.and.screwdriver"
        case .other: return "questionmark.circle"
        }
    }
}

struct AppInfo: Identifiable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let category: AppCategory
    let icon: String?
}

struct AppBlock: Identifiable {
    let id: String
    let appInfo: AppInfo
    var isBlocked: Bool
    var blockStartTime: Date?
    var blockEndTime: Date?
    var blockReason: String?
    
    init(appInfo: AppInfo, isBlocked: Bool = false) {
        self.id = UUID().uuidString
        self.appInfo = appInfo
        self.isBlocked = isBlocked
    }
}
