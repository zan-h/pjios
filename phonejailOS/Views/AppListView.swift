import SwiftUI

struct AppListView: View {
    @ObservedObject var viewModel: AppBlockViewModel
    @State private var searchText = ""
    @State private var selectedCategory: AppCategory?
    
    var body: some View {
        NavigationView {
            VStack {
                categoryFilter
                appList
            }
            .navigationTitle("Apps")
            .toolbar { refreshToolbar }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                CategoryButton(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(AppCategory.allCases, id: \ .self) { category in
                    CategoryButton(
                        title: category.rawValue.capitalized,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var appList: some View {
        List {
            ForEach(filteredApps) { app in
                AppRow(app: app, viewModel: viewModel)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search apps")
    }
    
    private var refreshToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                Task { await viewModel.loadBlockedApps() }
            }) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
    
    private var filteredApps: [AppBlock] {
        let allApps = viewModel.blockedApps
        let categoryApps: [AppBlock]
        if let category = selectedCategory {
            categoryApps = allApps.filter { $0.appInfo.category == category }
        } else {
            categoryApps = allApps
        }
        if searchText.isEmpty {
            return categoryApps
        } else {
            return categoryApps.filter { $0.appInfo.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct AppRow: View {
    let app: AppBlock
    @ObservedObject var viewModel: AppBlockViewModel
    @State private var showingUnblockRequest = false
    
    var body: some View {
        HStack {
            // App icon
            Image(systemName: app.appInfo.category.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            // App info
            VStack(alignment: .leading) {
                Text(app.appInfo.name)
                    .font(.headline)
                Text(app.appInfo.category.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Block/Unblock button
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
        .padding(.vertical, 4)
        .sheet(isPresented: $showingUnblockRequest) {
            UnblockRequestView(app: app, viewModel: viewModel)
        }
    }
}

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