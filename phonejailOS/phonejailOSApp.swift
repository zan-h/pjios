//
//  phonejailOSApp.swift
//  phonejailOS
//
//  Created by m on 06/05/2025.
//

import SwiftUI

@main
struct phonejailOSApp: App {
    @StateObject private var screenTimeService = ScreenTimeService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenTimeService)
                .task {
                    // Request Screen Time authorization when app starts
                    await requestScreenTimeAuthorizationIfNeeded()
                }
        }
    }
    
    private func requestScreenTimeAuthorizationIfNeeded() async {
        // Only request if not already determined
        if screenTimeService.authorizationStatus == .notDetermined {
            await screenTimeService.requestAuthorization()
        }
    }
}
