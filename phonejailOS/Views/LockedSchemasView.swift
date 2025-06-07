import SwiftUI

struct LockedSchemasView: View {
    let accessControlService: AccessControlService
    let jailkeeperViewModel: JailkeeperViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                VStack(spacing: 12) {
                    Text("Schemas Locked")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Strict Mode is active. Speak to the jail keeper for access.")
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
                    .cornerRadius(10)
                }
                
                Spacer()
                
                VStack(spacing: 6) {
                    Text("💡 Tip")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("Be honest and persuasive.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 6) {
                    Text("🔓 Alternative")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text("Deactivate schemas or disable Strict Mode.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("My Schemas")
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
    LockedSchemasView(
        accessControlService: AccessControlService(),
        jailkeeperViewModel: JailkeeperViewModel(llmService: LLMService()),
        selectedTab: .constant(0)
    )
} 