import SwiftUI

struct LockedSettingsView: View {
    let accessControlService: AccessControlService
    let jailkeeperViewModel: JailkeeperViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Lock icon with gear
                ZStack {
                    Image(systemName: "gear")
                        .font(.system(size: 80))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                        .offset(x: 20, y: 20)
                }
                
                VStack(spacing: 16) {
                    Text("Settings Locked")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Global Strict Mode is enabled and you have active schemas. Settings access is restricted to prevent bypassing your blocking rules. You must speak with the jail keeper to gain temporary access.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    requestAccessFromJailkeeper()
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Speak to Jail Keeper")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("🔒 Security Notice")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Settings are protected to prevent disabling Strict Mode while schemas are active. This ensures your blocking rules cannot be bypassed impulsively.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 8) {
                    Text("💡 Tip")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("Explain to your jail keeper why you need to access settings. They may grant temporary access for legitimate needs like adjusting notifications or other non-security settings.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func requestAccessFromJailkeeper() {
        // Set the jailkeeper into access control mode
        jailkeeperViewModel.enterAccessControlMode()
        
        // Switch to the Jailkeeper tab
        selectedTab = 1
    }
}

#Preview {
    LockedSettingsView(
        accessControlService: AccessControlService(),
        jailkeeperViewModel: JailkeeperViewModel(llmService: LLMService()),
        selectedTab: .constant(2)
    )
} 