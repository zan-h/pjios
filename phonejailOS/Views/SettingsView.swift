import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultUnblockDuration") private var defaultUnblockDuration: TimeInterval = 3600
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedPersonality") private var selectedPersonality = Personality.strict.rawValue
    
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
                Section("Jailkeeper Settings") {
                    Picker("Default Personality", selection: $selectedPersonality) {
                        ForEach(Personality.allCases, id: \.self) { personality in
                            Text(personality.rawValue.capitalized)
                                .tag(personality.rawValue)
                        }
                    }
                }
                
                Section("Unblock Settings") {
                    Picker("Default Unblock Duration", selection: $defaultUnblockDuration) {
                        ForEach(durations, id: \.0) { duration, label in
                            Text(label).tag(duration)
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
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
        }
    }
}

#Preview {
    SettingsView()
} 