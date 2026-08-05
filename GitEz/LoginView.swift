import SwiftUI

struct LoginView: View {
    @EnvironmentObject var gitService: GitService
    
    @State private var usernameInput: String = ""
    @State private var emailInput: String = ""
    @State private var tokenInput: String = ""
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            // Dark Liquid Glass Backdrop
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            Color(red: 0.05, green: 0.07, blue: 0.09)
                .opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // GLOWING GREEN GITHUB BADGE
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.1, green: 0.7, blue: 0.3), Color(red: 0.08, green: 0.5, blue: 0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 76, height: 76)
                        .shadow(color: Color(red: 0.1, green: 0.7, blue: 0.3).opacity(0.4), radius: 16, x: 0, y: 8)
                    
                    Image(systemName: "circle.hexagonpath")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 6) {
                    HStack(spacing: 1) {
                        Text("Git")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        Text("Ez")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("Simple GitHub workflows, beautifully done")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                // CREDENTIALS FORM CARD
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("GitHub Username")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.8))
                        
                        HStack {
                            Text("@")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.4))
                            TextField("yourhandle", text: $usernameInput)
                                .font(.system(size: 14, design: .rounded))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email address")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.8))
                        
                        TextField("you@example.com", text: $emailInput)
                            .font(.system(size: 14, design: .rounded))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("GitHub Personal Access Token (for Private Repos)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.8))
                            Spacer()
                            Text("Optional")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        
                        SecureField("ghp_12345... (required for private repos)", text: $tokenInput)
                            .font(.system(size: 13, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                    }
                    
                    Button(action: saveAndContinue) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle.hexagonpath")
                                .font(.system(size: 16, weight: .bold))
                            Text("Connect with GitHub")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.1, green: 0.65, blue: 0.3), Color(red: 0.08, green: 0.5, blue: 0.22)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color(red: 0.1, green: 0.65, blue: 0.3).opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(24)
                .frame(width: 400)
                .background(
                    ZStack {
                        VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                        Color.black.opacity(0.4)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                
                VStack(spacing: 4) {
                    Text("Your credentials stay local on your Mac.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                    Text("Private repos authenticate using your local Git / Personal Access Token.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                
                Spacer()
            }
            .padding(30)
        }
        .onAppear {
            usernameInput = gitService.gitUser.username
            emailInput = gitService.gitUser.email
            tokenInput = gitService.gitUser.token
        }
    }
    
    private func saveAndContinue() {
        if usernameInput.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "GitHub username is required"
            return
        }
        if emailInput.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Email address is required"
            return
        }
        _ = gitService.saveGitUser(username: usernameInput, email: emailInput, token: tokenInput)
    }
}

#Preview {
    LoginView()
        .environmentObject(GitService())
        .frame(width: 900, height: 600)
}
