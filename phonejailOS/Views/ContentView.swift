//
//  ContentView.swift
//  phonejailOS
//
//  Created by m on 06/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var jailkeeperViewModel: JailkeeperViewModel
    @State private var selectedTab = 0
    
    init() {
        print("ContentView: Initializing...")
        _jailkeeperViewModel = StateObject(wrappedValue: JailkeeperViewModel(llmService: LLMService()))
        print("ContentView: Initialization complete")
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SchemasView()
                .tabItem {
                    Label("Schemas", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(0)
                .onAppear {
                    print("Schemas tab appeared")
                }
            
            JailkeeperChatView(viewModel: jailkeeperViewModel)
                .tabItem {
                    Label("Jailkeeper", systemImage: "person.fill")
                }
                .tag(1)
                .onAppear {
                    print("Jailkeeper tab appeared")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
                .onAppear {
                    print("Settings tab appeared")
                }
        }
        .onAppear {
            print("ContentView: TabView appeared with selectedTab: \(selectedTab)")
        }
    }
}

#Preview {
    ContentView()
}
