//
//  ContentView.swift
//  phonejailOS
//
//  Created by m on 06/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var appBlockViewModel: AppBlockViewModel
    @StateObject private var jailkeeperViewModel: JailkeeperViewModel
    @State private var selectedTab = 0
    
    init() {
        _appBlockViewModel = StateObject(wrappedValue: AppBlockViewModel(screenTimeService: ScreenTimeService()))
        _jailkeeperViewModel = StateObject(wrappedValue: JailkeeperViewModel(llmService: LLMService()))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AppListView(viewModel: appBlockViewModel)
                .tabItem {
                    Label("Apps", systemImage: "app.badge")
                }
                .tag(0)
            
            JailkeeperChatView(viewModel: jailkeeperViewModel)
                .tabItem {
                    Label("Jailkeeper", systemImage: "person.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
