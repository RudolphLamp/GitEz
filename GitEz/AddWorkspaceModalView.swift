import SwiftUI

struct AddWorkspaceModalView: View {
    @EnvironmentObject var gitService: GitService
    
    @State private var folderPathInput: String = ""
    @State private var remoteUrlInput: String = "https://github.com/COS301-SE-2026/Cybersecurity-Awareness-Training-Platform"
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    gitService.showAddWorkspaceModal = false
                }
            
            // Glass Modal Container
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        Text("Add New Workspace")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: { gitService.showAddWorkspaceModal = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Text("Select a local project folder and link its remote GitHub repository URL.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Form Fields
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Local Project Directory Path")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.8))
                        
                        HStack {
                            TextField("/Users/path/to/project", text: $folderPathInput)
                                .font(.system(size: 13, design: .monospaced))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                            
                            Button(action: selectFolder) {
                                Text("Browse...")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Remote GitHub Repository URL")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.8))
                        
                        TextField("https://github.com/org/repo-name", text: $remoteUrlInput)
                            .font(.system(size: 13, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Text("Example: https://github.com/COS301-SE-2026/Cybersecurity-Awareness-Training-Platform")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: { gitService.showAddWorkspaceModal = false }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: submitAddWorkspace) {
                        Text("Add Workspace")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.25), Color(red: 0.08, green: 0.45, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)
            }
            .padding(24)
            .frame(width: 460)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    Color(red: 0.1, green: 0.12, blue: 0.15).opacity(0.92)
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
            if folderPathInput.isEmpty {
                folderPathInput = FileManager.default.currentDirectoryPath
            }
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            folderPathInput = url.path
        }
    }
    
    private func submitAddWorkspace() {
        if folderPathInput.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please select a local folder directory"
            return
        }
        
        gitService.addWorkspace(path: folderPathInput, remoteUrl: remoteUrlInput)
        gitService.showAddWorkspaceModal = false
    }
}

#Preview {
    AddWorkspaceModalView()
        .environmentObject(GitService())
}
