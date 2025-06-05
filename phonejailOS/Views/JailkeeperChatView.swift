import SwiftUI

struct JailkeeperChatView: View {
    @ObservedObject var viewModel: JailkeeperViewModel
    @State private var messageText = ""
    @State private var showingPersonalityPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Access control mode banner
                if viewModel.isInAccessControlMode {
                    accessControlBanner
                }
                
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.jailkeeper.conversationHistory) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        TextField(viewModel.isInAccessControlMode ? "Convince me to grant access..." : "Type your message...", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(viewModel.isLoading)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                        .disabled(messageText.isEmpty || viewModel.isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Jailkeeper")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPersonalityPicker = true }) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showingPersonalityPicker) {
                PersonalityPickerView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private var accessControlBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.orange)
                Text("Access Control Mode")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
            }
            
            Text("You need to convince the jailkeeper to grant you access to modify your schemas.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .border(Color.orange.opacity(0.3), width: 1)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let message = messageText
        messageText = ""
        
        Task {
            await viewModel.sendMessage(message)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            } else if message.sender == .system {
                // System messages are centered
            } else {
                // Jailkeeper messages align left
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading) {
                Text(message.content)
                    .padding()
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)
                
                if message.sender != .system {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if message.sender == .jailkeeper {
                Spacer()
            } else if message.sender == .system {
                // System messages are centered
            } else {
                // User messages align right
            }
        }
    }
    
    private var backgroundColor: Color {
        switch message.sender {
        case .user:
            return .blue
        case .jailkeeper:
            return .gray.opacity(0.2)
        case .system:
            return .green.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch message.sender {
        case .user:
            return .white
        case .jailkeeper:
            return .primary
        case .system:
            return .green
        }
    }
}

struct PersonalityPickerView: View {
    @ObservedObject var viewModel: JailkeeperViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(Personality.allCases, id: \.self) { personality in
                Button(action: {
                    viewModel.updatePersonality(personality)
                    dismiss()
                }) {
                    HStack {
                        Text(personality.rawValue.capitalized)
                        Spacer()
                        if viewModel.jailkeeper.personality == personality {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Choose Personality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    JailkeeperChatView(viewModel: JailkeeperViewModel(llmService: LLMService()))
} 