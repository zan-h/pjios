import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity
import Combine
import OSLog

enum ScreenTimeError: LocalizedError {
    case notAuthorized
    case appNotFound
    case blockFailed
    case unblockFailed
    case fetchFailed
    case schemaNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "ScreenTime access is not authorized"
        case .appNotFound:
            return "The requested app was not found"
        case .blockFailed:
            return "Failed to block the app"
        case .unblockFailed:
            return "Failed to unblock the app"
        case .fetchFailed:
            return "Failed to fetch installed apps"
        case .schemaNotFound:
            return "Blocking schema not found"
        }
    }
}

@MainActor
class ScreenTimeService: ObservableObject {
    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published private(set) var blockedApps: Set<String> = []
    @Published private(set) var activeSchemas: Set<UUID> = []
    
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private let logger = Logger(subsystem: "mizzron.phonejailOS", category: "ScreenTimeService")
    private let familyControlsStorage = FamilyControlsStorage.shared
    
    // Cache for application tokens
    private var applicationTokens: [String: ApplicationToken] = [:]
    private var schemaStores: [UUID: ManagedSettingsStore] = [:]
    
    init() {
        // Don't request authorization in init
        // Just check current status
        Task {
            await checkCurrentAuthorizationStatus()
        }
    }
    
    private func checkCurrentAuthorizationStatus() async {
        let center = AuthorizationCenter.shared
        switch center.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .approved:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        @unknown default:
            logger.error("Unknown authorization status encountered")
            authorizationStatus = .notDetermined
        }
    }
    
    func requestAuthorization() async {
        logger.info("Requesting ScreenTime authorization")
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            logger.info("ScreenTime authorization successful")
            authorizationStatus = .authorized
        } catch {
            logger.error("ScreenTime authorization failed: \(error.localizedDescription)")
            authorizationStatus = .denied
        }
    }
    
    func fetchInstalledApps() async throws -> [AppInfo] {
        guard authorizationStatus == .authorized else {
            logger.error("Attempted to fetch apps without authorization")
            throw ScreenTimeError.notAuthorized
        }
        
        logger.info("Fetching installed apps")
        
        // For now, return some common apps that users typically want to block
        // In a real implementation, you'd use Family Controls APIs that require user selection
        let commonApps: [AppInfo] = [
            AppInfo(
                id: "com.apple.mobilesafari",
                name: "Safari",
                bundleIdentifier: "com.apple.mobilesafari",
                category: .productivity,
                icon: nil
            ),
            AppInfo(
                id: "com.instagram.instagram",
                name: "Instagram",
                bundleIdentifier: "com.instagram.instagram",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.facebook.facebook",
                name: "Facebook",
                bundleIdentifier: "com.facebook.facebook",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.twitter.twitter",
                name: "Twitter",
                bundleIdentifier: "com.twitter.twitter",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.burbn.x",
                name: "X",
                bundleIdentifier: "com.burbn.x",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.tiktok.TikTok",
                name: "TikTok",
                bundleIdentifier: "com.tiktok.TikTok",
                category: .entertainment,
                icon: nil
            ),
            AppInfo(
                id: "com.youtube.youtube",
                name: "YouTube",
                bundleIdentifier: "com.youtube.youtube",
                category: .entertainment,
                icon: nil
            ),
            AppInfo(
                id: "com.spotify.spotify",
                name: "Spotify",
                bundleIdentifier: "com.spotify.spotify",
                category: .entertainment,
                icon: nil
            ),
            AppInfo(
                id: "com.netflix.netflix",
                name: "Netflix",
                bundleIdentifier: "com.netflix.netflix",
                category: .entertainment,
                icon: nil
            ),
            AppInfo(
                id: "com.reddit.reddit",
                name: "Reddit",
                bundleIdentifier: "com.reddit.reddit",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.snapchat.snapchat",
                name: "Snapchat",
                bundleIdentifier: "com.snapchat.snapchat",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.whatsapp.whatsapp",
                name: "WhatsApp",
                bundleIdentifier: "com.whatsapp.whatsapp",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.telegram.telegram",
                name: "Telegram",
                bundleIdentifier: "com.telegram.telegram",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.discord.discord",
                name: "Discord",
                bundleIdentifier: "com.discord.discord",
                category: .social,
                icon: nil
            ),
            AppInfo(
                id: "com.amazon.shopping",
                name: "Amazon",
                bundleIdentifier: "com.amazon.shopping",
                category: .other,
                icon: nil
            )
        ]
        
        logger.info("Found \(commonApps.count) common apps for blocking")
        return commonApps
    }
    
    // MARK: - Schema-based Blocking
    
    func activateSchema(_ schema: Schema) async throws {
        guard authorizationStatus == .authorized else {
            throw ScreenTimeError.notAuthorized
        }
        
        let schemaId = schema.id
        logger.info("Activating schema (legacy method): \(schema.name) with ID: \(schemaId)")
        
        // Create managed settings store for this schema
        let schemaStore = ManagedSettingsStore(named: .init(schemaId.uuidString))
        
        // Apply app restrictions
        var appTokens: Set<ApplicationToken> = []
        
        for appId in schema.selectedApps {
            // For now, we'll need to implement proper app token lookup
            // This is a simplified version that would need actual implementation
            // In practice, you'd need to maintain a mapping of app IDs to tokens
        }
        
        // Configure shield settings
        if !appTokens.isEmpty {
            schemaStore.shield.applications = appTokens
        }
        
        // Configure website restrictions
        if !schema.selectedWebsites.isEmpty {
            let webDomains = Set(schema.selectedWebsites.map { WebDomain(domain: $0) })
            schemaStore.webContent.blockedByFilter = WebContentSettings.FilterPolicy.specific(webDomains)
        }
        
        // Apply blocking conditions
        for condition in schema.blockingConditions {
            try await applyBlockingCondition(condition, to: schemaStore, schemaId: schemaId)
        }
        
        // Store the schema store for later reference
        schemaStores[schemaId] = schemaStore
        activeSchemas.insert(schemaId)
        
        // Update blocked apps tracking
        updateBlockedAppsSet()
        
        logger.info("Schema activated (legacy): \(schema.name). Active schemas: \(self.activeSchemas.count)")
    }
    
    func deactivateSchema(_ schema: Schema) async throws {
        let schemaId = schema.id
        
        // Stop monitoring for this schema first
        stopSchemaMonitoring(schema)
        
        // Check if this schema uses Family Controls
        if familyControlsStorage.hasSelection(for: schemaId) {
            try await deactivateFamilyControlsBlocking(for: schemaId)
        }
        
        // Clear managed settings for this schema
        if let schemaStore = schemaStores[schemaId] {
            schemaStore.clearAllSettings()
            schemaStores.removeValue(forKey: schemaId)
        }
        
        // Remove from active schemas
        activeSchemas.remove(schemaId)
        
        // Update blocked apps set to reflect the change
        updateBlockedAppsSet()
        
        logger.info("Schema deactivated: \(schema.name)")
    }
    
    /// Deactivate Family Controls blocking for a specific schema
    private func deactivateFamilyControlsBlocking(for schemaId: UUID) async throws {
        guard let schemaStore = schemaStores[schemaId] else {
            logger.warning("No schema store found for schema: \(schemaId)")
            return
        }
        
        // Clear the shield settings
        schemaStore.shield.applications = nil
        schemaStore.shield.webDomains = nil
        schemaStore.shield.applicationCategories = nil
        schemaStore.shield.webDomainCategories = nil
        
        logger.info("Cleared Family Controls blocking for schema: \(schemaId)")
    }
    
    func isAppBlocked(_ bundleIdentifier: String) -> Bool {
        return blockedApps.contains(bundleIdentifier)
    }
    
    func getBlockingSchemaForApp(_ bundleIdentifier: String) -> String? {
        // Find which active schema is blocking this app
        for schemaId in activeSchemas {
            if schemaStores[schemaId] != nil {
                // Check if this app is blocked by this schema
                // This is a simplified check - in practice you'd need to track which apps belong to which schema
                if blockedApps.contains(bundleIdentifier) {
                    return schemaId.uuidString
                }
            }
        }
        return nil
    }
    
    // MARK: - Private Methods
    
    private func extractAppInfo(from token: ApplicationToken) async -> AppInfo? {
        // This is a simplified version - in practice you'd use private APIs or maintain a mapping
        // For now, return a placeholder
        return AppInfo(
            id: UUID().uuidString,
            name: "App",
            bundleIdentifier: "com.example.app",
            category: .productivity,
            icon: nil
        )
    }
    
    private func scheduleSchemaMonitoring(_ schema: Schema) async throws {
        for condition in schema.blockingConditions {
            switch condition.type {
            case .schedule:
                try await scheduleTimeBasedMonitoring(schema, condition: condition)
            case .dailyUsageLimit:
                try await scheduleUsageLimitMonitoring(schema, condition: condition)
            case .custom:
                // Handle custom conditions
                break
            }
        }
    }
    
    private func scheduleTimeBasedMonitoring(_ schema: Schema, condition: BlockingCondition) async throws {
        guard let scheduleStart = condition.scheduleStart,
              let scheduleEnd = condition.scheduleEnd else {
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: scheduleStart,
            intervalEnd: scheduleEnd,
            repeats: condition.repeats
        )
        
        let activityName = DeviceActivityName("Schema_\(schema.id.uuidString)_Schedule")
        
        do {
            try center.startMonitoring(activityName, during: schedule)
            logger.info("Scheduled monitoring for schema: \(schema.name)")
        } catch {
            logger.error("Failed to schedule monitoring: \(error.localizedDescription)")
            throw ScreenTimeError.blockFailed
        }
    }
    
    private func scheduleUsageLimitMonitoring(_ schema: Schema, condition: BlockingCondition) async throws {
        guard condition.usageLimit != nil else {
            return
        }
        
        // Create a full-day schedule for usage monitoring
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("Schema_\(schema.id.uuidString)_Usage")
        
        do {
            try center.startMonitoring(activityName, during: schedule)
            logger.info("Scheduled usage monitoring for schema: \(schema.name)")
        } catch {
            logger.error("Failed to schedule usage monitoring: \(error.localizedDescription)")
            throw ScreenTimeError.blockFailed
        }
    }
    
    private func stopSchemaMonitoring(_ schema: Schema) {
        let scheduleActivity = DeviceActivityName("Schema_\(schema.id.uuidString)_Schedule")
        let usageActivity = DeviceActivityName("Schema_\(schema.id.uuidString)_Usage")
        
        center.stopMonitoring([scheduleActivity, usageActivity])
        logger.info("Stopped monitoring for schema: \(schema.name)")
    }
    
    private func updateBlockedAppsSet() {
        var allBlockedApps: Set<String> = []
        
        // Collect all apps blocked by active schemas
        for schemaId in self.activeSchemas {
            if let selection = self.familyControlsStorage.getSelection(for: schemaId) {
                // Note: We can't get bundle identifiers from ApplicationTokens directly
                // This is a limitation of Family Controls API for privacy reasons
                // For UI purposes, we'll track that apps are blocked but can't identify specific ones
                if !selection.applicationTokens.isEmpty {
                    // Add a placeholder to indicate apps are blocked by this schema
                    allBlockedApps.insert("family_controls_apps_\(schemaId.uuidString)")
                }
            }
        }
        
        self.blockedApps = allBlockedApps
        logger.info("Updated blocked apps set: \(self.blockedApps.count) entries for \(self.activeSchemas.count) active schemas")
    }
    
    // MARK: - Improved Legacy Methods (for backward compatibility)
    
    func blockApp(bundleIdentifier: String) async throws {
        guard authorizationStatus == .authorized else {
            logger.error("Attempted to block app without authorization")
            throw ScreenTimeError.notAuthorized
        }
        
        logger.info("Note: Blocking \(bundleIdentifier) - Family Controls requires user app selection")
        
        // For now, we'll add it to a blocked apps set for UI feedback
        // Real blocking requires ApplicationTokens from FamilyActivityPicker
        blockedApps.insert(bundleIdentifier)
        
        // In a production app, you would:
        // 1. Present FamilyActivityPicker to user
        // 2. Get ApplicationTokens from user selection
        // 3. Apply those tokens to ManagedSettingsStore
        
        logger.info("Added \(bundleIdentifier) to blocked apps list (UI feedback only)")
    }
    
    func unblockApp(bundleIdentifier: String) async throws {
        guard authorizationStatus == .authorized else {
            logger.error("Attempted to unblock app without authorization")
            throw ScreenTimeError.notAuthorized
        }
        
        logger.info("Unblocking app: \(bundleIdentifier)")
        blockedApps.remove(bundleIdentifier)
        
        logger.info("Removed \(bundleIdentifier) from blocked apps list")
    }
    
    private func getApplicationToken(for bundleIdentifier: String) async throws -> ApplicationToken {
        // Check cache first
        if let cachedToken = applicationTokens[bundleIdentifier] {
            return cachedToken
        }
        
        // IMPORTANT: In Family Controls, ApplicationTokens can only be obtained through
        // FamilyActivityPicker user selection. You cannot create them programmatically
        // from bundle identifiers. This is an Apple security restriction.
        
        logger.warning("Attempted to get ApplicationToken for \(bundleIdentifier) - this requires user selection through FamilyActivityPicker")
        throw ScreenTimeError.appNotFound
    }
    
    // MARK: - Schema Management Helper Methods
    
    private func applyBlockingCondition(_ condition: BlockingCondition, to store: ManagedSettingsStore, schemaId: UUID) async throws {
        switch condition.type {
        case .schedule:
            try await scheduleTimeBasedBlocking(condition, for: schemaId)
        case .dailyUsageLimit:
            try await scheduleUsageLimitBlocking(condition, for: schemaId)
        case .custom:
            // Handle custom conditions as needed
            break
        }
    }
    
    private func scheduleTimeBasedBlocking(_ condition: BlockingCondition, for schemaId: UUID) async throws {
        guard let scheduleStart = condition.scheduleStart,
              let scheduleEnd = condition.scheduleEnd else {
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: scheduleStart,
            intervalEnd: scheduleEnd,
            repeats: condition.repeats
        )
        
        let activityName = DeviceActivityName("Schema_\(schemaId.uuidString)_Schedule")
        
        do {
            try center.startMonitoring(activityName, during: schedule)
            logger.info("Scheduled time-based blocking for schema")
        } catch {
            logger.error("Failed to schedule time-based blocking: \(error.localizedDescription)")
            throw ScreenTimeError.blockFailed
        }
    }
    
    private func scheduleUsageLimitBlocking(_ condition: BlockingCondition, for schemaId: UUID) async throws {
        guard condition.usageLimit != nil else {
            return
        }
        
        // Create a full-day schedule for usage monitoring
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("Schema_\(schemaId.uuidString)_Usage")
        
        do {
            try center.startMonitoring(activityName, during: schedule)
            logger.info("Scheduled usage limit blocking for schema")
        } catch {
            logger.error("Failed to schedule usage limit blocking: \(error.localizedDescription)")
            throw ScreenTimeError.blockFailed
        }
    }
    
    // MARK: - Proper Family Controls Integration
    
    /// Present FamilyActivityPicker for user to select apps to block
    /// This is the correct way to get ApplicationTokens in Family Controls
    func presentAppSelection(completion: @escaping (FamilyActivitySelection) -> Void) {
        // This would typically be called from a SwiftUI view
        // The view would present FamilyActivityPicker and pass the selection back
        logger.info("App selection should be handled by presenting FamilyActivityPicker in UI")
    }
    
    /// Apply blocking using actual ApplicationTokens from user selection
    func applyBlocking(with selection: FamilyActivitySelection, for schemaId: UUID) async throws {
        guard authorizationStatus == .authorized else {
            throw ScreenTimeError.notAuthorized
        }
        
        logger.info("Applying blocking for schema \(schemaId) with \(selection.applicationTokens.count) apps and \(selection.webDomainTokens.count) websites")
        
        // Get or create schema store
        let schemaStore = ManagedSettingsStore(named: .init(schemaId.uuidString))
        
        // Apply app blocking using actual tokens
        if !selection.applicationTokens.isEmpty {
            schemaStore.shield.applications = selection.applicationTokens
            logger.info("Applied blocking to \(selection.applicationTokens.count) selected apps")
        }
        
        // Apply website blocking  
        if !selection.webDomainTokens.isEmpty {
            schemaStore.shield.webDomains = selection.webDomainTokens
            logger.info("Applied blocking to \(selection.webDomainTokens.count) selected websites")
        }
        
        // Apply category blocking if any - Fix: Use correct property assignment
        if !selection.categoryTokens.isEmpty {
            schemaStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            logger.info("Applied blocking to \(selection.categoryTokens.count) selected categories")
        }
        
        // Store for later reference
        schemaStores[schemaId] = schemaStore
        self.activeSchemas.insert(schemaId)
        
        // Update blocked apps tracking
        updateBlockedAppsSet()
        
        logger.info("Successfully applied Family Controls blocking for schema \(schemaId). Active schemas: \(self.activeSchemas.count)")
    }
    
    /// Force clear all settings for a schema (used when deleting schemas)
    func forceClearSchemaSettings(for schemaId: UUID) async {
        // Clear from Family Controls storage
        familyControlsStorage.removeSelection(for: schemaId)
        
        // Clear managed settings store if it exists
        if let schemaStore = schemaStores[schemaId] {
            schemaStore.clearAllSettings()
            schemaStores.removeValue(forKey: schemaId)
        } else {
            // Create a new store with the schema ID and clear it (in case it exists but we lost reference)
            let schemaStore = ManagedSettingsStore(named: .init(schemaId.uuidString))
            schemaStore.clearAllSettings()
        }
        
        // Remove from active schemas
        activeSchemas.remove(schemaId)
        
        // Stop any monitoring activities
        let scheduleActivity = DeviceActivityName("Schema_\(schemaId.uuidString)_Schedule")
        let usageActivity = DeviceActivityName("Schema_\(schemaId.uuidString)_Usage")
        center.stopMonitoring([scheduleActivity, usageActivity])
        
        // Update blocked apps set
        updateBlockedAppsSet()
        
        logger.info("Force cleared all settings for schema: \(schemaId)")
    }
    
    /// Sync active schemas from SchemaViewModel on startup
    func syncActiveSchemas(from schemas: [Schema]) {
        logger.info("Syncing active schemas from SchemaViewModel...")
        
        // Clear current active schemas
        self.activeSchemas.removeAll()
        
        // Add schemas that are marked as active in the UI
        for schema in schemas {
            if schema.status == .active || schema.status == .strictMode {
                self.activeSchemas.insert(schema.id)
                logger.info("Synced active schema: \(schema.name) (\(schema.id))")
            }
        }
        
        // Update blocked apps tracking
        updateBlockedAppsSet()
        
        logger.info("Sync complete. Active schemas: \(self.activeSchemas.count)")
    }
    
    /// Debug method to check current blocking state
    func debugBlockingState() {
        logger.info("=== BLOCKING STATE DEBUG ===")
        logger.info("Authorization Status: \(String(describing: self.authorizationStatus))")
        logger.info("Active Schemas Count: \(self.activeSchemas.count)")
        logger.info("Active Schema IDs: \(self.activeSchemas.map { $0.uuidString })")
        logger.info("Blocked Apps Count: \(self.blockedApps.count)")
        logger.info("Blocked Apps: \(Array(self.blockedApps))")
        logger.info("Schema Stores Count: \(self.schemaStores.count)")
        
        for (schemaId, _) in self.schemaStores {
            logger.info("Schema Store \(schemaId):")
            logger.info("  - Has Family Controls selection: \(self.familyControlsStorage.hasSelection(for: schemaId))")
            if let selection = self.familyControlsStorage.getSelection(for: schemaId) {
                logger.info("  - App tokens: \(selection.applicationTokens.count)")
                logger.info("  - Website tokens: \(selection.webDomainTokens.count)")
                logger.info("  - Category tokens: \(selection.categoryTokens.count)")
            }
        }
        logger.info("=== END DEBUG ===")
    }
}

// MARK: - Supporting Types
enum AuthorizationStatus {
    case notDetermined
    case authorized
    case denied
}
