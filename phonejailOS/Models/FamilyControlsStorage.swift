import Foundation
import FamilyControls

// MARK: - Family Controls Storage Helper
/// Since FamilyActivitySelection cannot be directly encoded/decoded,
/// we need to handle it separately in the ViewModel
class FamilyControlsStorage: ObservableObject {
    @Published private var selections: [UUID: FamilyActivitySelection] = [:]
    
    func setSelection(_ selection: FamilyActivitySelection, for schemaId: UUID) {
        selections[schemaId] = selection
    }
    
    func getSelection(for schemaId: UUID) -> FamilyActivitySelection? {
        return selections[schemaId]
    }
    
    func removeSelection(for schemaId: UUID) {
        selections.removeValue(forKey: schemaId)
    }
    
    func hasSelection(for schemaId: UUID) -> Bool {
        guard let selection = selections[schemaId] else { return false }
        return !selection.applicationTokens.isEmpty || !selection.webDomainTokens.isEmpty
    }
    
    func getAppCount(for schemaId: UUID) -> Int {
        return selections[schemaId]?.applicationTokens.count ?? 0
    }
    
    func getWebsiteCount(for schemaId: UUID) -> Int {
        return selections[schemaId]?.webDomainTokens.count ?? 0
    }
    
    func getCategoryCount(for schemaId: UUID) -> Int {
        return selections[schemaId]?.categoryTokens.count ?? 0
    }
}

// MARK: - Global Storage Instance
extension FamilyControlsStorage {
    static let shared = FamilyControlsStorage()
} 