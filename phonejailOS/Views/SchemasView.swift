//
//  SchemasView.swift
//  phonejailOS
//
//  Created by m on 06/05/2025.
//

import SwiftUI

struct SchemasView: View {
    @StateObject private var viewModel = SchemaViewModel(screenTimeService: ScreenTimeService())
    @State private var showingSchemaCreation = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    if !searchText.isEmpty || !viewModel.schemas.isEmpty {
                        searchBar
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                    
                    // User's schemas section
                    if !viewModel.schemas.isEmpty {
                        userSchemasSection
                    }
                    
                    // Starter schemas section
                    starterSchemasSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Schemas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSchemaCreation = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingSchemaCreation) {
                SchemaCreationView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private var userSchemasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("MY SCHEMAS")
            
            LazyVStack(spacing: 8) {
                ForEach(filteredUserSchemas) { schema in
                    SchemaRowView(
                        schema: schema,
                        onActivate: {
                            Task {
                                await viewModel.activateSchema(schema)
                            }
                        },
                        onDeactivate: {
                            Task {
                                await viewModel.deactivateSchema(schema)
                            }
                        },
                        onDelete: {
                            viewModel.deleteSchema(schema)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var starterSchemasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // New Schema button
            newSchemaButton
                .padding(.horizontal)
            
            sectionHeader("STARTER SCHEMAS")
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.starterSchemas) { schema in
                    SchemaRowView(
                        schema: schema,
                        isTemplate: true,
                        onActivate: {
                            viewModel.createSchema(from: schema)
                        },
                        onDeactivate: { },
                        onDelete: { }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var newSchemaButton: some View {
        Button(action: {
            showingSchemaCreation = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("New Schema")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var filteredUserSchemas: [Schema] {
        if searchText.isEmpty {
            return viewModel.schemas
        } else {
            return viewModel.schemas.filter { schema in
                schema.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct SchemaRowView: View {
    let schema: Schema
    let isTemplate: Bool
    let onActivate: () -> Void
    let onDeactivate: () -> Void
    let onDelete: () -> Void
    
    @State private var showingOptions = false
    
    init(schema: Schema, isTemplate: Bool = false, onActivate: @escaping () -> Void, onDeactivate: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.schema = schema
        self.isTemplate = isTemplate
        self.onActivate = onActivate
        self.onDeactivate = onDeactivate
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Schema icon
            ZStack {
                Circle()
                    .fill(schema.displayColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: schema.displayIcon)
                    .font(.title2)
                    .foregroundColor(schema.displayColor)
            }
            
            // Schema info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(schema.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !isTemplate {
                        statusIndicator
                    }
                }
                
                Text(schema.type.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onTapGesture {
            if isTemplate {
                onActivate()
            } else {
                showingOptions = true
            }
        }
        .confirmationDialog("Schema Options", isPresented: $showingOptions) {
            schemaOptions
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch schema.status {
        case .inactive:
            Circle()
                .fill(.gray.opacity(0.3))
                .frame(width: 8, height: 8)
        case .active:
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
        case .paused:
            Circle()
                .fill(.yellow)
                .frame(width: 8, height: 8)
        case .strictMode:
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
        case .scheduled:
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
        }
    }
    
    @ViewBuilder
    private var schemaOptions: some View {
        if schema.isActive {
            Button("Deactivate") {
                onDeactivate()
            }
            
            Button("Pause") {
                // Handle pause action
            }
        } else {
            Button("Activate") {
                onActivate()
            }
        }
        
        Button("Edit") {
            // Handle edit action
        }
        
        Button("Duplicate") {
            // Handle duplicate action
        }
        
        Button("Delete", role: .destructive) {
            onDelete()
        }
        
        Button("Cancel", role: .cancel) { }
    }
}

struct SchemaCreationView: View {
    @ObservedObject var viewModel: SchemaViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                HStack {
                    ForEach(1...3, id: \.self) { step in
                        Circle()
                            .fill(step <= viewModel.currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        if step < 3 {
                            Rectangle()
                                .fill(step < viewModel.currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding()
                
                // Step content
                stepContent
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Add Schema")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelSchemaCreation()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == 3 {
                        Button("Create") {
                            viewModel.createCustomSchema()
                            dismiss()
                        }
                        .disabled(!viewModel.canProceedToNextStep())
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1:
            step1Content
        case 2:
            step2Content
        case 3:
            step3Content
        default:
            EmptyView()
        }
    }
    
    private var step1Content: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Step 1")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("What should this schema be called?")
                .font(.title2)
                .foregroundColor(.secondary)
            
            TextField("e.g: No Social Media", text: $viewModel.newSchemaName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title3)
        }
        .padding()
    }
    
    private var step2Content: some View {
        VStack(spacing: 20) {
            Text("Select what to block")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose apps and websites you want to block in this schema.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Family Controls Selection Summary
            if viewModel.familyActivitySelection.applicationTokens.isEmpty && 
               viewModel.familyActivitySelection.webDomainTokens.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No content selected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap the button below to select apps and websites to block.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Content")
                        .font(.headline)
                    
                    if !viewModel.familyActivitySelection.applicationTokens.isEmpty {
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundColor(.blue)
                            Text("\(viewModel.familyActivitySelection.applicationTokens.count) app(s)")
                        }
                    }
                    
                    if !viewModel.familyActivitySelection.webDomainTokens.isEmpty {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                            Text("\(viewModel.familyActivitySelection.webDomainTokens.count) website(s)")
                        }
                    }
                    
                    if !viewModel.familyActivitySelection.categoryTokens.isEmpty {
                        HStack {
                            Image(systemName: "square.grid.3x3")
                                .foregroundColor(.orange)
                            Text("\(viewModel.familyActivitySelection.categoryTokens.count) categor(ies)")
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Select Content Button
            Button(action: {
                viewModel.presentFamilyActivityPicker()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(viewModel.familyActivitySelection.applicationTokens.isEmpty && 
                         viewModel.familyActivitySelection.webDomainTokens.isEmpty ? 
                         "Select Apps & Websites" : "Modify Selection")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Note about limitations
            Text("Note: Website blocking works in Safari. Third-party browsers may have limited support.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .sheet(isPresented: $viewModel.showingFamilyActivityPicker) {
            FamilyActivityPickerView(
                selection: $viewModel.familyActivitySelection,
                isPresented: $viewModel.showingFamilyActivityPicker,
                onSelectionComplete: { selection in
                    viewModel.handleFamilyActivitySelection(selection)
                }
            )
        }
    }
    
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Step 3")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("What should cause the content selected in Step 2 to be blocked?")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("You can configure multiple blocking conditions for a single schema. The content will be blocked when any of them are met.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical)
            
            // Condition options
            VStack(spacing: 12) {
                conditionCard(
                    title: "Schedule",
                    description: "When the clock is at specific times in the day.",
                    icon: "calendar",
                    action: {
                        let condition = BlockingCondition(type: .schedule)
                        viewModel.addBlockingCondition(condition)
                    }
                )
                
                conditionCard(
                    title: "Daily Usage Limit",
                    description: "When the content has been used for more than a specified combined amount of time in the day.",
                    icon: "clock",
                    action: {
                        let condition = BlockingCondition(type: .dailyUsageLimit)
                        viewModel.addBlockingCondition(condition)
                    }
                )
            }
        }
        .padding()
    }
    
    private func conditionCard(title: String, description: String, icon: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add This Condition")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var navigationButtons: some View {
        HStack {
            if viewModel.currentStep > 1 {
                Button("Back") {
                    viewModel.previousStep()
                }
                .frame(maxWidth: .infinity)
            }
            
            if viewModel.currentStep < 3 {
                Button("Next") {
                    viewModel.nextStep()
                }
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canProceedToNextStep())
            }
        }
        .padding()
    }
}

#Preview {
    SchemasView()
} 