import Foundation
import Combine

class AccessControlService: ObservableObject {
    @Published var isSchemaAccessLocked: Bool = false
    @Published var temporaryAccessGranted: Bool = false
    @Published var accessTimeRemaining: TimeInterval = 0
    
    private var accessTimer: Timer?
    private var settingsService: SettingsService?
    private var schemaViewModel: SchemaViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("🔧 AccessControlService: Initializing...")
        setupMonitoring()
        print("🔧 AccessControlService: Initialized")
    }
    
    deinit {
        accessTimer?.invalidate()
        cancellables.removeAll()
    }
    
    @MainActor
    func configure(settingsService: SettingsService, schemaViewModel: SchemaViewModel) {
        print("🔧 AccessControlService: Configuring with dependencies...")
        self.settingsService = settingsService
        self.schemaViewModel = schemaViewModel
        
        settingsService.$isGlobalStrictModeEnabled
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateAccessStatus()
                }
            }
            .store(in: &cancellables)
        
        schemaViewModel.$schemas
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateAccessStatus()
                }
            }
            .store(in: &cancellables)
        
        updateAccessStatus()
        print("🔧 AccessControlService: Configuration complete")
    }
    
    private func setupMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAccessTimer()
        }
    }
    
    @MainActor
    private func updateAccessStatus() {
        guard let settingsService = settingsService,
              let schemaViewModel = schemaViewModel else {
            print("🔍 AccessControl: Missing dependencies - settingsService: \(settingsService != nil), schemaViewModel: \(schemaViewModel != nil)")
            isSchemaAccessLocked = false
            return
        }
        
        let hasActiveSchemas = schemaViewModel.schemas.contains { schema in
            schema.status == .active || schema.status == .strictMode
        }
        
        let shouldBeLocked = settingsService.isGlobalStrictModeEnabled && 
                           hasActiveSchemas && 
                           !temporaryAccessGranted
        
        print("🔍 AccessControl Debug:")
        print("  - Global Strict Mode: \(settingsService.isGlobalStrictModeEnabled)")
        print("  - Has Active Schemas: \(hasActiveSchemas)")
        print("  - Schema Count: \(schemaViewModel.schemas.count)")
        print("  - Schema Statuses: \(schemaViewModel.schemas.map { "\($0.name): \($0.status)" })")
        print("  - Temporary Access: \(temporaryAccessGranted)")
        print("  - Should Be Locked: \(shouldBeLocked)")
        print("  - Currently Locked: \(isSchemaAccessLocked)")
        
        if isSchemaAccessLocked != shouldBeLocked {
            isSchemaAccessLocked = shouldBeLocked
            print("🔒 AccessControl: Lock status changed to \(shouldBeLocked)")
            
            if !shouldBeLocked {
                clearTemporaryAccess()
            }
        }
        
        settingsService.updateCanDisableStrictMode(hasActiveSchemas: hasActiveSchemas)
    }
    
    func grantTemporaryAccess(duration: TimeInterval) {
        temporaryAccessGranted = true
        accessTimeRemaining = duration
        isSchemaAccessLocked = false
        
        startAccessTimer()
        
        print("✅ Temporary access granted for \(Int(duration/60)) minutes")
    }
    
    @MainActor
    func revokeAccess() {
        clearTemporaryAccess()
        updateAccessStatus()
        
        print("🔒 Access revoked")
    }
    
    func extendAccess(additionalTime: TimeInterval) {
        if temporaryAccessGranted {
            accessTimeRemaining += additionalTime
            print("⏰ Access extended by \(Int(additionalTime/60)) minutes")
        }
    }
    
    private func clearTemporaryAccess() {
        temporaryAccessGranted = false
        accessTimeRemaining = 0
        accessTimer?.invalidate()
        accessTimer = nil
    }
    
    private func startAccessTimer() {
        accessTimer?.invalidate()
        
        accessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.accessTimeRemaining > 0 {
                self.accessTimeRemaining -= 1
            } else {
                self.clearTemporaryAccess()
                Task { @MainActor in
                    self.updateAccessStatus()
                }
                timer.invalidate()
                print("⏰ Temporary access expired")
            }
        }
    }
    
    private func updateAccessTimer() {
        // This method is called every second to update UI
        // The actual countdown is handled by startAccessTimer()
    }
    
    var accessTimeRemainingFormatted: String {
        let minutes = Int(accessTimeRemaining) / 60
        let seconds = Int(accessTimeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var shouldShowAccessBanner: Bool {
        return temporaryAccessGranted && accessTimeRemaining > 0
    }
    
    var accessStatusMessage: String {
        if temporaryAccessGranted {
            return "Temporary access granted • \(accessTimeRemainingFormatted) remaining"
        } else if isSchemaAccessLocked {
            return "Schema access is locked due to strict mode"
        } else {
            return "Schema access is available"
        }
    }
} 