import Foundation
import Combine

class SettingsService: ObservableObject {
    // MARK: - Published Properties
    @Published var isGlobalStrictModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGlobalStrictModeEnabled, forKey: "globalStrictModeEnabled")
        }
    }
    
    @Published var defaultUnblockDuration: TimeInterval {
        didSet {
            UserDefaults.standard.set(defaultUnblockDuration, forKey: "defaultUnblockDuration")
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    @Published var selectedPersonality: String {
        didSet {
            UserDefaults.standard.set(selectedPersonality, forKey: "selectedPersonality")
        }
    }
    
    // MARK: - Computed Properties
    var canDisableStrictMode: Bool {
        // Can only disable strict mode if no schemas are currently active
        // This will be updated when we integrate with schema monitoring
        return true // Placeholder - will be updated with actual logic
    }
    
    // MARK: - Initialization
    init() {
        // Load settings from UserDefaults
        self.isGlobalStrictModeEnabled = UserDefaults.standard.bool(forKey: "globalStrictModeEnabled")
        self.defaultUnblockDuration = UserDefaults.standard.double(forKey: "defaultUnblockDuration") != 0 
            ? UserDefaults.standard.double(forKey: "defaultUnblockDuration") 
            : 3600 // Default to 1 hour
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.selectedPersonality = UserDefaults.standard.string(forKey: "selectedPersonality") ?? Personality.strict.rawValue
    }
    
    // MARK: - Methods
    func toggleStrictMode() {
        if isGlobalStrictModeEnabled {
            // Trying to disable strict mode
            if canDisableStrictMode {
                isGlobalStrictModeEnabled = false
            } else {
                // Cannot disable - schemas are active
                // This should trigger UI feedback
                print("Cannot disable strict mode while schemas are active")
            }
        } else {
            // Enabling strict mode is always allowed
            isGlobalStrictModeEnabled = true
        }
    }
    
    func updateCanDisableStrictMode(hasActiveSchemas: Bool) {
        // This will be called by the access control system to update the bypass prevention
        // For now, we'll implement a simple version
        // In the full implementation, this would be more sophisticated
    }
    
    // MARK: - Reset Methods
    func resetToDefaults() {
        isGlobalStrictModeEnabled = false
        defaultUnblockDuration = 3600
        notificationsEnabled = true
        selectedPersonality = Personality.strict.rawValue
    }
} 