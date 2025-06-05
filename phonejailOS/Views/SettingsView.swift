import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsService: SettingsService
    @State private var showingStrictModeInfo = false
    
    private let durations: [(TimeInterval, String)] = [
        (1800, "30 minutes"),
        (3600, "1 hour"),
        (7200, "2 hours"),
        (14400, "4 hours"),
        (28800, "8 hours")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Strict Mode")
                                .font(.body)
                            Text("Locks schemas tab when active schemas exist")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $settingsService.isGlobalStrictModeEnabled)
                    }
                    
                    Button(action: {
                        showingStrictModeInfo = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("How Strict Mode Works")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Security")
                } footer: {
                    Text("When strict mode is enabled, you must convince the jail keeper to access your schemas if any are currently active.")
                }
                
                Section("Jailkeeper Settings") {
                    Picker("Default Personality", selection: $settingsService.selectedPersonality) {
                        ForEach(Personality.allCases, id: \.self) { personality in
                            Text(personality.rawValue.capitalized)
                                .tag(personality.rawValue)
                        }
                    }
                }
                
                Section("Unblock Settings") {
                    Picker("Default Unblock Duration", selection: $settingsService.defaultUnblockDuration) {
                        ForEach(durations, id: \.0) { duration, label in
                            Text(label).tag(duration)
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $settingsService.notificationsEnabled)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Strict Mode", isPresented: $showingStrictModeInfo) {
                Button("Got it") { }
            } message: {
                Text("""
                When Strict Mode is enabled:
                
                • If you have active schemas, the Schemas tab becomes locked
                • You must convince the jail keeper through conversation to gain temporary access
                • If no schemas are active, you can freely access the Schemas tab
                • You cannot disable Strict Mode while schemas are active
                
                This prevents impulsive changes to your blocking rules during active sessions.
                """)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsService())
} 