import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var gitService: GitService
    
    @State private var usernameInput: String = ""
    @State private var emailInput: String = ""
    @State private var showSuccessAlert: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header Banner
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)
                            .shadow(color: .blue.opacity(0.35), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .foregroundColor(.white)
                    }
                    
                    Text("Git Account Credentials")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    Text("Configures global git user.name and user.email for your commits")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                // Login / Configuration Glass Card
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Git Configuration")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        if gitService.gitUser.isValid {
                            HStack(spacing: 5) {
                                Circle().fill(Color.green).frame(width: 7, height: 7)
                                Text("Configured")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    
                    Divider().opacity(0.5)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Git Username")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                                TextField("e.g. rudolph-dev", text: $usernameInput)
                                    .font(.system(size: 14, design: .rounded))
                                    .textFieldStyle(.plain)
                            }
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Git Email")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.secondary)
                                TextField("e.g. dev@example.com", text: $emailInput)
                                    .font(.system(size: 14, design: .rounded))
                                    .textFieldStyle(.plain)
                            }
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    
                    HStack {
                        Button(action: {
                            usernameInput = gitService.gitUser.username
                            emailInput = gitService.gitUser.email
                        }) {
                            Text("Reset to Current Git Config")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: saveCredentials) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Credentials")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(colors: [.blue, Color(red: 0.2, green: 0.4, blue: 0.9)], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .disabled(usernameInput.trimmingCharacters(in: .whitespaces).isEmpty || emailInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.top, 6)
                }
                .liquidGlassCard(cornerRadius: 24, paddingAmount: 28)
                .padding(.horizontal, 20)
            }
            .padding(24)
        }
        .onAppear {
            usernameInput = gitService.gitUser.username
            emailInput = gitService.gitUser.email
        }
        .alert("Credentials Saved", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your global Git username and email have been successfully updated.")
        }
    }
    
    private func saveCredentials() {
        if gitService.saveGitUser(username: usernameInput, email: emailInput) {
            showSuccessAlert = true
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(GitService())
        .frame(width: 600, height: 500)
}
