//
//  phonejailOSApp.swift
//  phonejailOS
//
//  Created by m on 06/05/2025.
//

import SwiftUI

@main
struct phonejailOSApp: App {
    @StateObject private var appBlockViewModel = AppBlockViewModel(screenTimeService: ScreenTimeService())
    @StateObject private var jailkeeperViewModel = JailkeeperViewModel(llmService: LLMService())
    
    var body: some Scene {
        WindowGroup {
            TabView {
                AppListView(viewModel: appBlockViewModel)
                    .tabItem {
                        Label("Apps", systemImage: "app.badge")
                    }
                
                JailkeeperChatView(viewModel: jailkeeperViewModel)
                    .tabItem {
                        Label("Jailkeeper", systemImage: "person.fill")
                    }
            }
        }
    }
}
