import SwiftUI

struct PhoneJailSplashView: View {
    let appName: String
    let onDismiss: () -> Void
    let onContactJailkeeper: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Prison bars animation
                VStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 6, height: 120)
                            .offset(y: isAnimating ? 0 : -20)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .delay(Double(index) * 0.1),
                                value: isAnimating
                            )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 140)
                )
                
                // Main message
                VStack(spacing: 16) {
                    Text("📱⛓️")
                        .font(.system(size: 60))
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .animation(.bouncy(duration: 1.0), value: isAnimating)
                    
                    Text("App in Phone Jail")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("**\(appName)** is currently blocked")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Speak to the jail keeper if you want access")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: onContactJailkeeper) {
                        HStack {
                            Image(systemName: "person.fill.questionmark")
                            Text("Contact Jail Keeper")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: onDismiss) {
                        Text("Go Back")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    PhoneJailSplashView(
        appName: "Instagram",
        onDismiss: { },
        onContactJailkeeper: { }
    )
} 