import Foundation
import SwiftUI
import Combine
import FamilyControls
import OSLog

@MainActor
class SchemaViewModel: ObservableObject {
    @Published var schemas: [Schema] = []
    @Published var starterSchemas: [Schema] = Schema.starterSchemas
    
    // Schema creation flow
    @Published var isCreatingSchema = false
    @Published var currentStep = 1
    @Published var newSchemaName = ""
    @Published var selectedApps: Set<String> = []
    @Published var selectedWebsites: Set<String> = []
    @Published var blockingConditions: [BlockingCondition] = []
    
    // Family Controls Integration
    @Published var familyActivitySelection = FamilyActivitySelection()
    @Published var showingFamilyActivityPicker = false
    private let familyControlsStorage = FamilyControlsStorage.shared
    
    // Error handling
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let screenTimeService: ScreenTimeService
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "mizzron.phonejailOS", category: "SchemaViewModel")
    
    init(screenTimeService: ScreenTimeService) {
        self.screenTimeService = screenTimeService
        loadSchemas()
        
        // Observe ScreenTime service changes
        self.screenTimeService.$authorizationStatus
            .sink { [weak self] status in
                self?.handleAuthorizationStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Schema Management
    
    private func loadSchemas() {
        guard let data = UserDefaults.standard.data(forKey: "saved_schemas") else {
            logger.info("No saved schemas found")
            return
        }
        
        do {
            schemas = try JSONDecoder().decode([Schema].self, from: data)
            logger.info("Loaded \(self.schemas.count) schemas")
        } catch {
            logger.error("Failed to load schemas: \(error.localizedDescription)")
            schemas = []
        }
    }
    
    func createSchema() {
        isCreatingSchema = true
        currentStep = 1
        resetCreationFlow()
    }
    
    func nextStep() {
        if currentStep < 3 {
            currentStep += 1
        } else {
            completeSchemaCreation()
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func cancelSchemaCreation() {
        isCreatingSchema = false
        resetCreationFlow()
    }
    
    private func resetCreationFlow() {
        currentStep = 1
        newSchemaName = ""
        selectedApps.removeAll()
        selectedWebsites.removeAll()
        blockingConditions.removeAll()
        familyActivitySelection = FamilyActivitySelection()
    }
    
    private func completeSchemaCreation() {
        guard !newSchemaName.isEmpty else {
            showError("Please enter a schema name")
            return
        }
        
        // Create new schema
        var newSchema = Schema(
            name: newSchemaName,
            type: .custom
        )
        
        // Set additional properties
        newSchema.selectedApps = selectedApps
        newSchema.selectedWebsites = selectedWebsites
        newSchema.blockingConditions = blockingConditions
        
        // Store Family Controls selection separately
        if !familyActivitySelection.applicationTokens.isEmpty || !familyActivitySelection.webDomainTokens.isEmpty {
            familyControlsStorage.setSelection(familyActivitySelection, for: newSchema.id)
        }
        
        schemas.append(newSchema)
        saveSchemas()
        
        logger.info("Created new schema: \(self.newSchemaName) with \(self.familyActivitySelection.applicationTokens.count) apps and \(self.familyActivitySelection.webDomainTokens.count) websites")
        
        // Reset and close
        resetCreationFlow()
        isCreatingSchema = false
    }
    
    // MARK: - Family Controls Integration
    
    func presentFamilyActivityPicker() {
        showingFamilyActivityPicker = true
    }
    
    func handleFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        familyActivitySelection = selection
        
        // Update legacy selected apps/websites for UI display
        selectedApps.removeAll()
        selectedWebsites.removeAll()
        
        // Track the count for UI purposes
        if !selection.applicationTokens.isEmpty {
            selectedApps.insert("family_controls_apps_\(selection.applicationTokens.count)")
        }
        
        if !selection.webDomainTokens.isEmpty {
            selectedWebsites.insert("family_controls_websites_\(selection.webDomainTokens.count)")
        }
        
        logger.info("Family activity selection updated: \(selection.applicationTokens.count) apps, \(selection.webDomainTokens.count) websites")
    }
    
    // MARK: - Schema Activation
    
    func activateSchema(_ schema: Schema) async {
        do {
            // Check if we have Family Controls selection for this schema
            if let familySelection = familyControlsStorage.getSelection(for: schema.id),
               (!familySelection.applicationTokens.isEmpty || !familySelection.webDomainTokens.isEmpty) {
                // Use real Family Controls blocking
                try await screenTimeService.applyBlocking(with: familySelection, for: schema.id)
                logger.info("Schema activated with Family Controls: \(schema.name)")
            } else {
                // Fall back to legacy activation
                try await screenTimeService.activateSchema(schema)
                logger.info("Schema activated with legacy method: \(schema.name)")
            }
            
            // Update schema status
            if let index = schemas.firstIndex(where: { $0.id == schema.id }) {
                schemas[index].status = .active
                saveSchemas()
            }
        } catch {
            logger.error("Failed to activate schema: \(error.localizedDescription)")
            showError("Failed to activate schema: \(error.localizedDescription)")
        }
    }
    
    func deactivateSchema(_ schema: Schema) async {
        do {
            try await screenTimeService.deactivateSchema(schema)
            
            // Update schema status
            if let index = schemas.firstIndex(where: { $0.id == schema.id }) {
                schemas[index].status = .inactive
                saveSchemas()
            }
            
            logger.info("Schema deactivated: \(schema.name)")
        } catch {
            logger.error("Failed to deactivate schema: \(error.localizedDescription)")
            showError("Failed to deactivate schema: \(error.localizedDescription)")
        }
    }
    
    func deleteSchema(_ schema: Schema) {
        // Deactivate schema if it's active
        if schema.status == .active {
            Task {
                await deactivateSchema(schema)
            }
        }
        
        // Remove Family Controls selection
        familyControlsStorage.removeSelection(for: schema.id)
        
        schemas.removeAll { $0.id == schema.id }
        saveSchemas()
    }
    
    // MARK: - Blocking Conditions
    
    func addBlockingCondition(_ condition: BlockingCondition) {
        blockingConditions.append(condition)
    }
    
    func removeBlockingCondition(at index: Int) {
        guard index < blockingConditions.count else { return }
        blockingConditions.remove(at: index)
    }
    
    // MARK: - Persistence
    
    private func saveSchemas() {
        do {
            let data = try JSONEncoder().encode(schemas)
            UserDefaults.standard.set(data, forKey: "saved_schemas")
            logger.info("Schemas saved successfully")
        } catch {
            logger.error("Failed to save schemas: \(error.localizedDescription)")
            showError("Failed to save schemas")
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func handleAuthorizationStatusChange(_ status: AuthorizationStatus) {
        // Handle changes in ScreenTime authorization
        if status == .denied {
            // Deactivate all active schemas
            Task {
                for schema in schemas where schema.status == .active {
                    await deactivateSchema(schema)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var activeSchemas: [Schema] {
        return schemas.filter { $0.status == .active }
    }
    
    var inactiveSchemas: [Schema] {
        return schemas.filter { $0.status == .inactive }
    }
    
    var hasActiveSchemas: Bool {
        return !activeSchemas.isEmpty
    }
    
    // MARK: - Schema Templates
    
    func getSchemaTemplate(type: SchemaType) -> Schema? {
        return starterSchemas.first { $0.type == type }
    }
    
    // MARK: - Helper Methods for UI
    
    func hasFamilyControlsSelection(for schema: Schema) -> Bool {
        return familyControlsStorage.hasSelection(for: schema.id)
    }
    
    func getFamilyControlsAppCount(for schema: Schema) -> Int {
        return familyControlsStorage.getAppCount(for: schema.id)
    }
    
    func getFamilyControlsWebsiteCount(for schema: Schema) -> Int {
        return familyControlsStorage.getWebsiteCount(for: schema.id)
    }
    
    // MARK: - Missing Methods for UI Integration
    
    func createSchema(from template: Schema) {
        var newSchema = Schema(name: template.name, type: template.type)
        newSchema.blockingConditions = template.blockingConditions
        newSchema.selectedApps = template.selectedApps
        newSchema.selectedWebsites = template.selectedWebsites
        
        schemas.append(newSchema)
        saveSchemas()
        
        logger.info("Created schema from template: \(template.name)")
    }
    
    func createCustomSchema() {
        completeSchemaCreation()
    }
    
    func canProceedToNextStep() -> Bool {
        switch currentStep {
        case 1:
            return !newSchemaName.isEmpty
        case 2:
            return !familyActivitySelection.applicationTokens.isEmpty || 
                   !familyActivitySelection.webDomainTokens.isEmpty ||
                   !selectedApps.isEmpty || !selectedWebsites.isEmpty
        case 3:
            return !blockingConditions.isEmpty
        default:
            return false
        }
    }
} 