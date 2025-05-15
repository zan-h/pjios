import SwiftUI

struct JailkeeperChatView: View {
    @ObservedObject var viewModel: JailkeeperViewModel
    @State private var messageText = ""
    @State private var showingPersonalityPicker = false
    
    var body: some View {
        NavigationView {
            VStack {
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
                        TextField("Type your message...", text: $messageText)
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
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading) {
                Text(message.content)
                    .padding()
                    .background(message.sender == .user ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.sender == .jailkeeper {
                Spacer()
            }
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