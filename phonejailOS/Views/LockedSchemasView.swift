import SwiftUI

struct LockedSchemasView: View {
    let accessControlService: AccessControlService
    let jailkeeperViewModel: JailkeeperViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                VStack(spacing: 16) {
                    Text("Schemas Locked")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Global Strict Mode is enabled and you have active schemas. To modify your schemas, you must speak directly with the jail keeper to convince them to grant you temporary access.")
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
                    Text("💡 Tip")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("Be honest and persuasive when talking to your jail keeper. They will evaluate your request based on their personality and may grant you temporary access if convinced.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 8) {
                    Text("🔓 Alternative")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("You can also deactivate all your schemas or disable Strict Mode in Settings when no schemas are active.")
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