import SwiftUI

struct SettingsModalView: View {
    @EnvironmentObject var gitService: GitService
    
    @State private var usernameInput: String = ""
    @State private var emailInput: String = ""
    @State private var tokenInput: String = ""
    @State private var defaultBranchInput: String = "main"
    @State private var autoPush: Bool = false
    
    var body: some View {
        ZStack {
            // Dark Backdrop Overlay
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    gitService.showSettingsModal = false
                }
            
            // Glass Modal Container
            VStack(alignment: .leading, spacing: 20) {
                // Modal Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { gitService.showSettingsModal = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Form Fields
                VStack(spacing: 12) {
                    HStack {
                        Text("GitHub Username")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.7))
                        Spacer()
                        HStack {
                            Text("@")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.4))
                            TextField("username", text: $usernameInput)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 140)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                    
                    HStack {
                        Text("Email")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.7))
                        Spacer()
                        TextField("email@example.com", text: $emailInput)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 180)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Personal Access Token")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.7))
                            Spacer()
                            Text("Required for private repos")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        
                        SecureField("ghp_12345... (GitHub Token)", text: $tokenInput)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                    
                    HStack {
                        Text("Default branch")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.7))
                        Spacer()
                        TextField("main", text: $defaultBranchInput)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
                
                Button(action: saveAndClose) {
                    Text("Save & Close")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.25), Color(red: 0.08, green: 0.45, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(24)
            .frame(width: 420)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    Color(red: 0.1, green: 0.12, blue: 0.15).opacity(0.9)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 12)
        }
        .onAppear {
            usernameInput = gitService.gitUser.username
            emailInput = gitService.gitUser.email
            tokenInput = gitService.gitUser.token
        }
    }
    
    private func saveAndClose() {
        _ = gitService.saveGitUser(username: usernameInput, email: emailInput, token: tokenInput)
        gitService.showSettingsModal = false
    }
}

#Preview {
    SettingsModalView()
        .environmentObject(GitService())
}
