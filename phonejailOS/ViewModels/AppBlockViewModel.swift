import Foundation
import SwiftUI

@MainActor
class AppBlockViewModel: ObservableObject {
    @Published private(set) var apps: [AppBlock] = []
    @Published private(set) var selectedCategory: AppCategory?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let screenTimeService: ScreenTimeService
    
    init(screenTimeService: ScreenTimeService) {
        self.screenTimeService = screenTimeService
        Task {
            await loadApps()
        }
    }
    
    static func create() async -> AppBlockViewModel {
        let screenTimeService = await ScreenTimeService()
        return AppBlockViewModel(screenTimeService: screenTimeService)
    }
    
    func loadApps() async {
        isLoading = true
        error = nil
        
        do {
            let appInfos = try await screenTimeService.fetchInstalledApps()
            apps = appInfos.map { AppBlock(appInfo: $0) }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func toggleAppBlock(_ app: AppBlock) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].isBlocked.toggle()
            if apps[index].isBlocked {
                apps[index].blockStartTime = Date()
            } else {
                apps[index].blockStartTime = nil
                apps[index].blockEndTime = nil
                apps[index].blockReason = nil
            }
        }
    }
    
    func setBlockTime(_ app: AppBlock, startTime: Date, endTime: Date, reason: String) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].blockStartTime = startTime
            apps[index].blockEndTime = endTime
            apps[index].blockReason = reason
            apps[index].isBlocked = true
        }
    }
    
    var filteredApps: [AppBlock] {
        guard let category = selectedCategory else { return apps }
        return apps.filter { $0.appInfo.category == category }
    }
    
    var blockedApps: [AppBlock] {
        // For now, return all apps. You can filter for blocked only if needed.
        return apps
    }
    
    func toggleBlock(_ app: AppBlock) async {
        toggleAppBlock(app)
    }
    
    func requestUnblock(_ app: AppBlock, duration: TimeInterval) async {
        // TODO: Implement real unblock request logic
        // For now, just unblock immediately
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].isBlocked = false
            apps[index].blockEndTime = Date().addingTimeInterval(duration)
        }
    }
    
    func clearError() {
        error = nil
    }
    
    func loadBlockedApps() async {
        await loadApps()
    }
}
