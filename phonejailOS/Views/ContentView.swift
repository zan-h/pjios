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
    @StateObject private var accessControlService = AccessControlService()
    @StateObject private var settingsService = SettingsService()
    @StateObject private var schemaViewModel: SchemaViewModel
    @State private var selectedTab = 0
    
    init() {
        print("ContentView: Initializing...")
        _jailkeeperViewModel = StateObject(wrappedValue: JailkeeperViewModel(llmService: LLMService()))
        _schemaViewModel = StateObject(wrappedValue: SchemaViewModel(screenTimeService: ScreenTimeService()))
        print("ContentView: Initialization complete")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Debug overlay
            debugOverlay
            
            TabView(selection: $selectedTab) {
                // Schemas tab with access control
                Group {
                    if accessControlService.isSchemaAccessLocked && !accessControlService.temporaryAccessGranted {
                        LockedSchemasView(
                            accessControlService: accessControlService,
                            jailkeeperViewModel: jailkeeperViewModel,
                            selectedTab: $selectedTab
                        )
                        .onAppear {
                            print("🔒 ContentView: Showing LockedSchemasView")
                        }
                    } else {
                        SchemasView()
                            .environmentObject(accessControlService)
                            .onAppear {
                                print("📱 ContentView: Showing SchemasView - isLocked: \(accessControlService.isSchemaAccessLocked), tempAccess: \(accessControlService.temporaryAccessGranted)")
                            }
                    }
                }
                .tabItem {
                    Label("Schemas", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(0)
                .onAppear {
                    print("Schemas tab appeared")
                    // Ensure configuration happens when schemas tab appears
                    configureAccessControl()
                }
                
                JailkeeperChatView(viewModel: jailkeeperViewModel)
                    .tabItem {
                        Label("Jailkeeper", systemImage: "person.fill")
                    }
                    .tag(1)
                    .onAppear {
                        print("Jailkeeper tab appeared")
                    }
                
                // Settings tab with access control
                Group {
                    if accessControlService.isSchemaAccessLocked && !accessControlService.temporaryAccessGranted {
                        LockedSettingsView(
                            accessControlService: accessControlService,
                            jailkeeperViewModel: jailkeeperViewModel,
                            selectedTab: $selectedTab
                        )
                        .onAppear {
                            print("🔒 ContentView: Showing LockedSettingsView")
                        }
                    } else {
                        SettingsView()
                            .environmentObject(settingsService)
                            .onAppear {
                                print("⚙️ ContentView: Showing SettingsView - isLocked: \(accessControlService.isSchemaAccessLocked), tempAccess: \(accessControlService.temporaryAccessGranted)")
                            }
                    }
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
                .onAppear {
                    print("Settings tab appeared")
                    // Ensure configuration happens when settings tab appears
                    configureAccessControl()
                }
            }
        }
        .onAppear {
            print("ContentView: TabView appeared with selectedTab: \(selectedTab)")
            configureAccessControl()
            configureJailkeeper()
        }
        .environmentObject(schemaViewModel)
        .environmentObject(settingsService)
    }
    
    private func configureAccessControl() {
        print("🔧 ContentView: Configuring AccessControlService...")
        accessControlService.configure(settingsService: settingsService, schemaViewModel: schemaViewModel)
        print("🔧 ContentView: AccessControlService configured")
    }
    
    private func configureJailkeeper() {
        print("🔧 ContentView: Configuring JailkeeperViewModel...")
        jailkeeperViewModel.setAccessControlService(accessControlService)
        print("🔧 ContentView: JailkeeperViewModel configured")
    }
    
    private var debugOverlay: some View {
        VStack(spacing: 4) {
            HStack {
                Text("DEBUG:")
                    .font(.caption2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack {
                Text("Global Strict Mode: \(settingsService.isGlobalStrictModeEnabled ? "ON" : "OFF")")
                    .font(.caption2)
                Spacer()
            }
            
            HStack {
                Text("Active Schemas: \(schemaViewModel.schemas.filter { $0.status == .active }.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("ScreenTime Active: \(schemaViewModel.screenTimeActiveCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text("Access Locked: \(accessControlService.isSchemaAccessLocked ? "YES" : "NO")")
                    .font(.caption2)
                    .foregroundColor(accessControlService.isSchemaAccessLocked ? .red : .green)
                Spacer()
            }
            
            if accessControlService.isSchemaAccessLocked {
                HStack {
                    Text("Protected: Schemas & Settings")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
            
            if accessControlService.temporaryAccessGranted {
                HStack {
                    Text("Temp Access: \(Int(accessControlService.accessTimeRemaining))s remaining")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .border(Color.gray, width: 1)
        .onTapGesture {
            schemaViewModel.debugBlockingState()
        }
    }
}

#Preview {
    ContentView()
}
