import Foundation
import SwiftUI
import FamilyControls

// MARK: - Schema Types
enum SchemaType: String, CaseIterable, Identifiable, Codable {
    case quickBlock = "Quick Block"
    case healthyWorkHabits = "Healthy Work Habits"
    case stressFreeWeekends = "Stress-free Weekends"
    case stressFreeMornings = "Stress-free Mornings"
    case stressFreeEvenings = "Stress-free Evenings"
    case thirtyMinuteWatchlist = "30 Minute Watchlist"
    case highControl = "High Control"
    case siriPowered = "Siri-Powered Schema"
    case focusMode = "Focus Mode"
    case studyMode = "Study Mode"
    case digitalDetox = "Digital Detox"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .quickBlock:
            return "Quick Block"
        case .healthyWorkHabits:
            return "Healthy Work Habits"
        case .stressFreeWeekends:
            return "Stress-free Weekends"
        case .stressFreeMornings:
            return "Stress-free Mornings"
        case .stressFreeEvenings:
            return "Stress-free Evenings"
        case .thirtyMinuteWatchlist:
            return "30 Minute Watchlist"
        case .highControl:
            return "High Control"
        case .siriPowered:
            return "Siri-Powered Schema"
        case .focusMode:
            return "Focus Mode"
        case .studyMode:
            return "Study Mode"
        case .digitalDetox:
            return "Digital Detox"
        case .custom:
            return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .quickBlock:
            return "Blocks content indefinitely"
        case .healthyWorkHabits:
            return "Blocks content outside working hours"
        case .stressFreeWeekends:
            return "Blocks content on weekends"
        case .stressFreeMornings:
            return "Blocks content every morning until 10am"
        case .stressFreeEvenings:
            return "Blocks content every evening from 5pm"
        case .thirtyMinuteWatchlist:
            return "Prevents content from being used for more than 30 minutes"
        case .highControl:
            return "Blocks content using both a schedule and a daily usage limit"
        case .siriPowered:
            return "A schema with no native conditions that relies completely on its integration with the Shortcuts app"
        case .focusMode:
            return "Blocks distracting apps during focus periods"
        case .studyMode:
            return "Optimized for study sessions with minimal distractions"
        case .digitalDetox:
            return "Complete digital cleanse for mental wellbeing"
        case .custom:
            return "Create your own blocking rules"
        }
    }
    
    var iconName: String {
        switch self {
        case .quickBlock:
            return "lock.fill"
        case .healthyWorkHabits:
            return "desktopcomputer"
        case .stressFreeWeekends:
            return "leaf.fill"
        case .stressFreeMornings:
            return "sun.max.fill"
        case .stressFreeEvenings:
            return "bed.double.fill"
        case .thirtyMinuteWatchlist:
            return "clock.fill"
        case .highControl:
            return "hourglass"
        case .siriPowered:
            return "gear"
        case .focusMode:
            return "🎯"
        case .studyMode:
            return "📚"
        case .digitalDetox:
            return "🌱"
        case .custom:
            return "🔧"
        }
    }
    
    var color: Color {
        switch self {
        case .quickBlock:
            return .purple
        case .healthyWorkHabits:
            return .green
        case .stressFreeWeekends:
            return .blue
        case .stressFreeMornings:
            return .orange
        case .stressFreeEvenings:
            return .purple
        case .thirtyMinuteWatchlist:
            return .teal
        case .highControl:
            return .purple
        case .siriPowered:
            return .blue
        case .focusMode:
            return .indigo
        case .studyMode:
            return .brown
        case .digitalDetox:
            return .mint
        case .custom:
            return .gray
        }
    }
    
    var emoji: String {
        switch self {
        case .quickBlock: return "🔒"
        case .healthyWorkHabits: return "💻"
        case .stressFreeWeekends: return "🍃"
        case .stressFreeMornings: return "☀️"
        case .stressFreeEvenings: return "🛏️"
        case .thirtyMinuteWatchlist: return "⏰"
        case .highControl: return "⏳"
        case .siriPowered: return "⚙️"
        case .focusMode: return "🎯"
        case .studyMode: return "📚"
        case .digitalDetox: return "🌱"
        case .custom: return "🔧"
        }
    }
}

// MARK: - Blocking Conditions
enum BlockingConditionType: String, CaseIterable, Identifiable, Codable {
    case schedule = "schedule"
    case dailyUsageLimit = "dailyUsageLimit"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .schedule:
            return "Schedule"
        case .dailyUsageLimit:
            return "Daily Usage Limit"
        case .custom:
            return "Custom Condition"
        }
    }
    
    var description: String {
        switch self {
        case .schedule:
            return "When the clock is at specific times in the day."
        case .dailyUsageLimit:
            return "When the content has been used for more than a specified combined amount of time in the day."
        case .custom:
            return "Custom blocking condition with specific requirements."
        }
    }
    
    var iconName: String {
        switch self {
        case .schedule:
            return "calendar"
        case .dailyUsageLimit:
            return "clock"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}

struct BlockingCondition: Identifiable, Codable {
    let id = UUID()
    let type: BlockingConditionType
    
    // Schedule-based properties
    var scheduleStart: DateComponents?
    var scheduleEnd: DateComponents?
    var repeats: Bool = true
    var activeDays: Set<Weekday> = Set(Weekday.allCases)
    
    // Usage limit properties
    var usageLimit: TimeInterval? // in seconds
    
    // Custom condition properties
    var customTitle: String?
    var customDescription: String?
    
    init(type: BlockingConditionType) {
        self.type = type
    }
}

enum Weekday: String, CaseIterable, Identifiable, Codable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

// MARK: - Schema Status
enum SchemaStatus: String, CaseIterable, Identifiable, Codable {
    case inactive = "inactive"
    case active = "active"
    case paused = "paused"
    case strictMode = "strictMode"
    case scheduled = "scheduled"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .inactive:
            return "Inactive"
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .strictMode:
            return "Blocking Strictly"
        case .scheduled:
            return "Scheduled"
        }
    }
    
    var color: Color {
        switch self {
        case .inactive:
            return .gray
        case .active:
            return .green
        case .paused:
            return .yellow
        case .strictMode:
            return .red
        case .scheduled:
            return .blue
        }
    }
}

// MARK: - Main Schema Model
struct Schema: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: SchemaType
    var status: SchemaStatus = .inactive
    
    // Content selection
    var selectedApps: Set<String> = []
    var selectedWebsites: Set<String> = []
    var selectedCategories: Set<String> = []
    
    // Blocking conditions
    var blockingConditions: [BlockingCondition] = []
    
    // Advanced settings
    var isStrictModeEnabled: Bool = false
    var isPaused: Bool = false
    var pauseEndTime: Date?
    
    // Metadata
    var createdAt: Date = Date()
    var lastModified: Date = Date()
    
    // Description property
    var description: String {
        return type.description
    }
    
    init(
        name: String,
        type: SchemaType = .custom
    ) {
        self.name = name
        self.type = type
    }
    
    // Computed properties
    var isCustom: Bool {
        return type == .custom
    }
    
    var isActive: Bool {
        return status == .active || status == .strictMode
    }
    
    var hasTimeConditions: Bool {
        return blockingConditions.contains { $0.type == .schedule }
    }
    
    var hasUsageLimits: Bool {
        return blockingConditions.contains { $0.type == .dailyUsageLimit }
    }
    
    var displayIcon: String {
        return type.iconName
    }
    
    var displayColor: Color {
        return type.color
    }
    
    mutating func updateLastModified() {
        lastModified = Date()
    }
    
    // Helper computed properties for UI
    var isScheduled: Bool {
        blockingConditions.contains { $0.type == .schedule }
    }
    
    var totalAppsAndWebsites: Int {
        return selectedApps.count + selectedWebsites.count
    }
}

// MARK: - Starter Schemas
extension Schema {
    static var starterSchemas: [Schema] {
        var schemas: [Schema] = []
        
        // Quick Block
        var quickBlock = Schema(name: "Quick Block", type: .quickBlock)
        quickBlock.blockingConditions = [
            BlockingCondition(type: .custom)
        ]
        schemas.append(quickBlock)
        
        // Healthy Work Habits
        var healthyWork = Schema(name: "Healthy Work Habits", type: .healthyWorkHabits)
        var workCondition = BlockingCondition(type: .schedule)
        workCondition.scheduleStart = DateComponents(hour: 9, minute: 0)
        workCondition.scheduleEnd = DateComponents(hour: 17, minute: 0)
        workCondition.activeDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        workCondition.repeats = true
        healthyWork.blockingConditions = [workCondition]
        schemas.append(healthyWork)
        
        // Stress-free Weekends
        var weekends = Schema(name: "Stress-free Weekends", type: .stressFreeWeekends)
        var weekendCondition = BlockingCondition(type: .schedule)
        weekendCondition.scheduleStart = DateComponents(hour: 0, minute: 0)
        weekendCondition.scheduleEnd = DateComponents(hour: 23, minute: 59)
        weekendCondition.activeDays = [.saturday, .sunday]
        weekendCondition.repeats = true
        weekends.blockingConditions = [weekendCondition]
        schemas.append(weekends)
        
        // Stress-free Mornings
        var mornings = Schema(name: "Stress-free Mornings", type: .stressFreeMornings)
        var morningCondition = BlockingCondition(type: .schedule)
        morningCondition.scheduleStart = DateComponents(hour: 6, minute: 0)
        morningCondition.scheduleEnd = DateComponents(hour: 10, minute: 0)
        morningCondition.activeDays = Set(Weekday.allCases)
        morningCondition.repeats = true
        mornings.blockingConditions = [morningCondition]
        schemas.append(mornings)
        
        // Stress-free Evenings
        var evenings = Schema(name: "Stress-free Evenings", type: .stressFreeEvenings)
        var eveningCondition = BlockingCondition(type: .schedule)
        eveningCondition.scheduleStart = DateComponents(hour: 17, minute: 0)
        eveningCondition.scheduleEnd = DateComponents(hour: 23, minute: 59)
        eveningCondition.activeDays = Set(Weekday.allCases)
        eveningCondition.repeats = true
        evenings.blockingConditions = [eveningCondition]
        schemas.append(evenings)
        
        // 30 Minute Watchlist
        var watchlist = Schema(name: "30 Minute Watchlist", type: .thirtyMinuteWatchlist)
        var usageCondition = BlockingCondition(type: .dailyUsageLimit)
        usageCondition.usageLimit = 30 * 60 // 30 minutes in seconds
        watchlist.blockingConditions = [usageCondition]
        schemas.append(watchlist)
        
        // High Control
        var highControl = Schema(name: "High Control", type: .highControl)
        var scheduleCondition = BlockingCondition(type: .schedule)
        scheduleCondition.scheduleStart = DateComponents(hour: 9, minute: 0)
        scheduleCondition.scheduleEnd = DateComponents(hour: 17, minute: 0)
        scheduleCondition.activeDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        scheduleCondition.repeats = true
        
        var limitCondition = BlockingCondition(type: .dailyUsageLimit)
        limitCondition.usageLimit = 60 * 60 // 1 hour in seconds
        
        highControl.blockingConditions = [scheduleCondition, limitCondition]
        schemas.append(highControl)
        
        // Siri-Powered Schema
        var siriPowered = Schema(name: "Siri-Powered Schema", type: .siriPowered)
        siriPowered.blockingConditions = [
            BlockingCondition(type: .custom)
        ]
        schemas.append(siriPowered)
        
        return schemas
    }
} 