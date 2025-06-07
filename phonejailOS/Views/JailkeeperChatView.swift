import SwiftUI

struct JailkeeperChatView: View {
    @ObservedObject var viewModel: JailkeeperViewModel
    @State private var messageText = ""
    @State private var showingPersonalityPicker = false
    @State private var showingTherapeuticMenu = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode indicator and controls
                modeHeader
                
                // Access control mode banner (only in authority mode)
                if viewModel.currentMode == .authority && viewModel.isInAccessControlMode {
                    accessControlBanner
                }
                
                // Therapeutic features banner (only in guide mode)
                if viewModel.currentMode == .guide {
                    therapeuticBanner
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
                        TextField(placeholderText, text: $messageText)
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
            .navigationTitle("Digital Wellness Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.currentMode == .guide {
                        Button(action: { showingTherapeuticMenu = true }) {
                            Image(systemName: "brain.head.profile")
                        }
                    }
                    
                    Button(action: { showingPersonalityPicker = true }) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showingPersonalityPicker) {
                PersonalityPickerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingTherapeuticMenu) {
                TherapeuticMenuView(viewModel: viewModel)
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
    
    private var modeHeader: some View {
        HStack {
            // Mode indicator
            HStack(spacing: 8) {
                Image(systemName: viewModel.currentMode == .guide ? "heart.circle.fill" : "lock.shield.fill")
                    .foregroundColor(viewModel.currentMode == .guide ? .green : .orange)
                
                Text(viewModel.currentMode.rawValue + " Mode")
                    .font(.headline)
                    .foregroundColor(viewModel.currentMode == .guide ? .green : .orange)
            }
            
            Spacer()
            
            // Mode switch (only show in guide mode, authority mode is triggered by access control)
            if viewModel.currentMode == .guide {
                Button("Switch to Authority") {
                    viewModel.switchToAuthorityMode()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var therapeuticBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                Text("Digital Wellness Guide")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                
                if viewModel.hasActiveGoals {
                    Text("\(viewModel.therapeuticProgress.currentGoals.count) active goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let theme = viewModel.currentTheme {
                HStack {
                    Text("Focus: \(theme.description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            if viewModel.engagementStreak > 0 {
                HStack {
                    Text("🔥 \(viewModel.engagementStreak) day engagement streak")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .border(Color.green.opacity(0.3), width: 1)
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
    
    private var placeholderText: String {
        if viewModel.currentMode == .authority && viewModel.isInAccessControlMode {
            return "Convince me to grant access..."
        } else if viewModel.currentMode == .guide {
            if let theme = viewModel.currentTheme {
                switch theme {
                case .dailyCheckin:
                    return "How are you feeling about your digital habits today?"
                case .goalSetting:
                    return "What digital wellness goal would you like to work on?"
                case .triggerExploration:
                    return "What situations trigger your excessive app use?"
                case .copingStrategies:
                    return "What helps you when you feel the urge to use apps mindlessly?"
                default:
                    return "Share your thoughts about your digital wellness journey..."
                }
            } else {
                return "How can I support your digital wellness today?"
            }
        } else {
            return "Type your message..."
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
            } else if message.sender == .system {
                // System messages are centered
            } else {
                // Jailkeeper messages align left
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                // Theme indicator for therapeutic conversations
                if let theme = message.theme, message.sender == .jailkeeper {
                    HStack {
                        Image(systemName: themeIcon(for: theme))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(theme.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
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
    
    private func themeIcon(for theme: ConversationTheme) -> String {
        switch theme {
        case .dailyCheckin:
            return "sun.max"
        case .weeklyReview:
            return "calendar"
        case .goalSetting:
            return "target"
        case .triggerExploration:
            return "magnifyingglass"
        case .copingStrategies:
            return "shield"
        case .mindfulness:
            return "leaf"
        case .progressCelebration:
            return "party.popper"
        case .setbackSupport:
            return "heart"
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

struct TherapeuticMenuView: View {
    @ObservedObject var viewModel: JailkeeperViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Quick Actions") {
                    Button(action: {
                        Task {
                            await viewModel.startDailyCheckin()
                        }
                        dismiss()
                    }) {
                        Label("Daily Check-in", systemImage: "sun.max")
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.startWeeklyReview()
                        }
                        dismiss()
                    }) {
                        Label("Weekly Review", systemImage: "calendar")
                    }
                }
                
                Section("Conversation Themes") {
                    ForEach(ConversationTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            viewModel.setConversationTheme(theme)
                            dismiss()
                        }) {
                            HStack {
                                Label(theme.rawValue, systemImage: themeIcon(for: theme))
                                Spacer()
                                if viewModel.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Progress") {
                    HStack {
                        Text("Current Goals")
                        Spacer()
                        Text("\(viewModel.therapeuticProgress.currentGoals.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Completed Goals")
                        Spacer()
                        Text("\(viewModel.therapeuticProgress.completedGoals.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Engagement Streak")
                        Spacer()
                        Text("\(viewModel.engagementStreak) days")
                            .foregroundColor(.orange)
                    }
                }
                
                Section("Actions") {
                    Button("Clear Conversation") {
                        viewModel.clearMessages()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Therapeutic Tools")
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
    
    private func themeIcon(for theme: ConversationTheme) -> String {
        switch theme {
        case .dailyCheckin:
            return "sun.max"
        case .weeklyReview:
            return "calendar"
        case .goalSetting:
            return "target"
        case .triggerExploration:
            return "magnifyingglass"
        case .copingStrategies:
            return "shield"
        case .mindfulness:
            return "leaf"
        case .progressCelebration:
            return "party.popper"
        case .setbackSupport:
            return "heart"
        }
    }
}

struct PersonalityPickerView: View {
    @ObservedObject var viewModel: JailkeeperViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Personality") {
                    ForEach(Personality.allCases, id: \.self) { personality in
                        Button(action: {
                            viewModel.updatePersonality(personality)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(personality.rawValue.capitalized)
                                        .font(.headline)
                                    Spacer()
                                    if viewModel.jailkeeper.personality == personality {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                Text(personality.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Current Mode") {
                    HStack {
                        Text("Mode")
                        Spacer()
                        Text(viewModel.currentMode.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(viewModel.currentMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
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