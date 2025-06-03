import SwiftUI
import FamilyControls

struct FamilyActivityPickerView: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool
    @State private var isPickerPresented = false
    
    let onSelectionComplete: (FamilyActivitySelection) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Select Apps to Block")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose which apps and websites you want to include in this blocking schema.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                Spacer()
                
                // Selection Summary
                if !selection.applicationTokens.isEmpty || !selection.webDomainTokens.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Content")
                            .font(.headline)
                        
                        if !selection.applicationTokens.isEmpty {
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundColor(.blue)
                                Text("\(selection.applicationTokens.count) app(s) selected")
                            }
                        }
                        
                        if !selection.webDomainTokens.isEmpty {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.green)
                                Text("\(selection.webDomainTokens.count) website(s) selected")
                            }
                        }
                        
                        if !selection.categoryTokens.isEmpty {
                            HStack {
                                Image(systemName: "square.grid.3x3")
                                    .foregroundColor(.orange)
                                Text("\(selection.categoryTokens.count) categor(ies) selected")
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Select Content Button
                Button(action: {
                    isPickerPresented = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(selection.applicationTokens.isEmpty && selection.webDomainTokens.isEmpty ? 
                             "Select Apps & Websites" : "Modify Selection")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button("Done") {
                        onSelectionComplete(selection)
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selection.applicationTokens.isEmpty && selection.webDomainTokens.isEmpty ? 
                                Color(.systemGray4) : Color.blue)
                    .cornerRadius(12)
                    .disabled(selection.applicationTokens.isEmpty && selection.webDomainTokens.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Content Selection")
            .navigationBarTitleDisplayMode(.inline)
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
        }
    }
}

#Preview {
    FamilyActivityPickerView(
        selection: .constant(FamilyActivitySelection()),
        isPresented: .constant(true),
        onSelectionComplete: { _ in }
    )
} 