import SwiftUI

struct AppListView: View {
    @ObservedObject var viewModel: AppBlockViewModel
    @State private var selectedCategory: AppCategory?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.authorizationStatus {
                case .notDetermined:
                    AuthorizationRequestView(viewModel: viewModel)
                case .denied:
                    AuthorizationDeniedView()
                case .authorized:
                    AuthorizedContentView(viewModel: viewModel, selectedCategory: $selectedCategory)
                }
            }
            .navigationTitle("Apps")
            .alert("Error", isPresented: $showingError, presenting: viewModel.error) { _ in
                Button("OK") {
                    viewModel.clearError()
                }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
        .onReceive(viewModel.$error) { error in
            showingError = error != nil
        }
    }
}

// MARK: - Authorization Request View
struct AuthorizationRequestView: View {
    let viewModel: AppBlockViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Screen Time Access Required")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text("This app needs access to Screen Time to manage app blocking.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    await viewModel.requestScreenTimeAuthorization()
                }
            }) {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Authorization Denied View
struct AuthorizationDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Screen Time Access Denied")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text("Please enable Screen Time access in Settings to use this app.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Authorized Content View
struct AuthorizedContentView: View {
    @ObservedObject var viewModel: AppBlockViewModel
    @Binding var selectedCategory: AppCategory?
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Apps...")
            } else if viewModel.apps.isEmpty {
                EmptyStateView()
            } else {
                AppListContentView(viewModel: viewModel, selectedCategory: $selectedCategory)
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("No Apps Found")
                .font(.title2)
            Text("No apps are available for blocking.")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - App List Content View
struct AppListContentView: View {
    @ObservedObject var viewModel: AppBlockViewModel
    @Binding var selectedCategory: AppCategory?
    
    var filteredApps: [AppBlock] {
        if let category = selectedCategory {
            return viewModel.apps.filter { $0.appInfo.category == category }
        }
        return viewModel.apps
    }
    
    var body: some View {
        List {
            Section {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
            
            Section {
                ForEach(filteredApps) { app in
                    AppRow(app: app, viewModel: viewModel)
                }
            }
        }
        .refreshable {
            await viewModel.loadApps()
        }
    }
}

// MARK: - Category Picker View
struct CategoryPickerView: View {
    @Binding var selectedCategory: AppCategory?
    
    var body: some View {
        Picker("Category", selection: $selectedCategory) {
            Text("All").tag(Optional<AppCategory>.none)
            ForEach(AppCategory.allCases) { category in
                Text(category.rawValue).tag(Optional(category))
            }
        }
        .pickerStyle(.menu)
    }
}

// MARK: - App Row View
struct AppRow: View {
    let app: AppBlock
    @ObservedObject var viewModel: AppBlockViewModel
    @State private var showingUnblockRequest = false
    
    var body: some View {
        HStack {
            AppIconView(category: app.appInfo.category)
            AppInfoView(app: app)
            Spacer()
            BlockToggleButton(app: app, showingUnblockRequest: $showingUnblockRequest, viewModel: viewModel)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingUnblockRequest) {
            UnblockRequestView(app: app, viewModel: viewModel)
        }
    }
}

// MARK: - App Icon View
struct AppIconView: View {
    let category: AppCategory
    
    var body: some View {
        Image(systemName: category.icon)
            .font(.title2)
            .frame(width: 40, height: 40)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
}

// MARK: - App Info View
struct AppInfoView: View {
    let app: AppBlock
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(app.appInfo.name)
                .font(.headline)
            Text(app.appInfo.category.rawValue.capitalized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Block Toggle Button
struct BlockToggleButton: View {
    let app: AppBlock
    @Binding var showingUnblockRequest: Bool
    @ObservedObject var viewModel: AppBlockViewModel
    
    var body: some View {
        Button(action: {
            if app.isBlocked {
                showingUnblockRequest = true
            } else {
                Task {
                    await viewModel.toggleBlock(app)
                }
            }
        }) {
            Text(app.isBlocked ? "Blocked" : "Unblocked")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(app.isBlocked ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

// MARK: - Unblock Request View
struct UnblockRequestView: View {
    let app: AppBlock
    @ObservedObject var viewModel: AppBlockViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration: TimeInterval = 3600 // 1 hour default
    
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
                Section("Request Duration") {
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(durations, id: \.0) { duration, label in
                            Text(label).tag(duration)
                        }
                    }
                }
                
                Section {
                    Button("Request Unblock") {
                        Task {
                            await viewModel.requestUnblock(app, duration: selectedDuration)
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Request Unblock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AppListView(viewModel: AppBlockViewModel(screenTimeService: ScreenTimeService()))
} 