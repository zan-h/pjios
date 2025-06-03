import Foundation
import SwiftUI
import OSLog

@MainActor
class AppBlockViewModel: ObservableObject {
    @Published private(set) var apps: [AppBlock] = []
    @Published private(set) var selectedCategory: AppCategory?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    
    private let screenTimeService: ScreenTimeService
    private let logger = Logger(subsystem: "mizzron.phonejailOS", category: "AppBlockViewModel")
    
    init(screenTimeService: ScreenTimeService) {
        self.screenTimeService = screenTimeService
        
        // Observe authorization status changes
        Task { [weak self] in
            guard let self = self else { return }
            for await status in screenTimeService.$authorizationStatus.values {
                self.authorizationStatus = status
                if status == .authorized {
                    await self.loadApps()
                }
            }
        }
    }
    
    static func create() async -> AppBlockViewModel {
        let screenTimeService = await ScreenTimeService()
        return AppBlockViewModel(screenTimeService: screenTimeService)
    }
    
    func requestScreenTimeAuthorization() async {
        logger.info("Requesting ScreenTime authorization")
        await screenTimeService.requestAuthorization()
    }
    
    func loadApps() async {
        isLoading = true
        error = nil
        
        do {
            let appInfos = try await screenTimeService.fetchInstalledApps()
            self.apps = appInfos.map { AppBlock(appInfo: $0) }
            logger.info("Successfully loaded \(self.apps.count) apps")
        } catch {
            self.error = error
            logger.error("Failed to load apps: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func toggleAppBlock(_ app: AppBlock) {
        if let index = self.apps.firstIndex(where: { $0.id == app.id }) {
            self.apps[index].isBlocked.toggle()
            if self.apps[index].isBlocked {
                self.apps[index].blockStartTime = Date()
                logger.info("App blocked: \(app.appInfo.name)")
            } else {
                self.apps[index].blockStartTime = nil
                self.apps[index].blockEndTime = nil
                self.apps[index].blockReason = nil
                logger.info("App unblocked: \(app.appInfo.name)")
            }
        }
    }
    
    func setBlockTime(_ app: AppBlock, startTime: Date, endTime: Date, reason: String) {
        if let index = self.apps.firstIndex(where: { $0.id == app.id }) {
            self.apps[index].blockStartTime = startTime
            self.apps[index].blockEndTime = endTime
            self.apps[index].blockReason = reason
            self.apps[index].isBlocked = true
            logger.info("Block time set for app: \(app.appInfo.name)")
        }
    }
    
    var filteredApps: [AppBlock] {
        guard let category = selectedCategory else { return self.apps }
        return self.apps.filter { $0.appInfo.category == category }
    }
    
    var blockedApps: [AppBlock] {
        return self.apps.filter { $0.isBlocked }
    }
    
    func toggleBlock(_ app: AppBlock) async {
        guard authorizationStatus == .authorized else {
            logger.warning("Attempted to toggle block without authorization")
            await requestScreenTimeAuthorization()
            return
        }
        
        do {
            if app.isBlocked {
                try await screenTimeService.unblockApp(bundleIdentifier: app.appInfo.bundleIdentifier)
            } else {
                try await screenTimeService.blockApp(bundleIdentifier: app.appInfo.bundleIdentifier)
            }
            toggleAppBlock(app)
        } catch {
            self.error = error
            logger.error("Failed to toggle block: \(error.localizedDescription)")
        }
    }
    
    func requestUnblock(_ app: AppBlock, duration: TimeInterval) async {
        guard authorizationStatus == .authorized else {
            logger.warning("Attempted to request unblock without authorization")
            await requestScreenTimeAuthorization()
            return
        }
        
        do {
            try await screenTimeService.unblockApp(bundleIdentifier: app.appInfo.bundleIdentifier)
            if let index = self.apps.firstIndex(where: { $0.id == app.id }) {
                self.apps[index].isBlocked = false
                self.apps[index].blockEndTime = Date().addingTimeInterval(duration)
                logger.info("Unblock requested for app: \(app.appInfo.name), duration: \(duration) seconds")
            }
        } catch {
            self.error = error
            logger.error("Failed to request unblock: \(error.localizedDescription)")
        }
    }
    
    func clearError() {
        error = nil
    }
    
    func loadBlockedApps() async {
        await loadApps()
    }
}
