import SwiftUI
import AppKit

struct AddWorkspaceModalView: View {
    @EnvironmentObject var gitService: GitService
    
    @State private var step: Int = 1
    @State private var folderPath: String = ""
    @State private var remoteUrlInput: String = ""
    @State private var isFetchingBranches: Bool = false
    @State private var availableBranches: [String] = []
    @State private var selectedBranch: String = "main"
    @State private var newBranchInput: String = ""
    @State private var isCreatingNewBranch: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    gitService.showAddWorkspaceModal = false
                }
            
            VStack(alignment: .leading, spacing: 20) {
                // HEADER
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.91, green: 0.29, blue: 0.25))
                        
                        Text("Add New Workspace")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("STEP \(step) OF 4")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.91, green: 0.29, blue: 0.25))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.91, green: 0.29, blue: 0.25).opacity(0.15))
                        .cornerRadius(6)
                    
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
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // WIZARD STEPS
                switch step {
                case 1:
                    renderStep1FolderSelection()
                case 2:
                    renderStep2RemoteUrlInput()
                case 3:
                    renderStep3BranchSelection()
                case 4:
                    renderStep4IDECompletion()
                default:
                    EmptyView()
                }
            }
            .padding(24)
            .frame(width: 520)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    Color(red: 0.1, green: 0.07, blue: 0.08).opacity(0.92)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 12)
        }
    }
    
    // STEP 1: FOLDER SELECTION
    @ViewBuilder
    private func renderStep1FolderSelection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 1: Select Project Folder")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Choose a local repository or project directory on your Mac.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Color.white.opacity(0.6))
            
            HStack(spacing: 10) {
                TextField("/Users/username/Projects/MyRepo", text: $folderPath)
                    .font(.system(size: 13, design: .monospaced))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                
                Button(action: selectFolderWithPanel) {
                    Text("Browse...")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                Spacer()
                Button(action: {
                    if !folderPath.isEmpty { step = 2 }
                }) {
                    Text("Next: Remote Repository →")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            folderPath.isEmpty ? Color.white.opacity(0.1) : Color(red: 0.85, green: 0.25, blue: 0.22)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(folderPath.isEmpty)
            }
            .padding(.top, 8)
        }
    }
    
    // STEP 2: REMOTE URL INPUT
    @ViewBuilder
    private func renderStep2RemoteUrlInput() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 2: Link Remote GitHub Repository")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Enter the remote GitHub repository URL (defaults to empty).")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Color.white.opacity(0.6))
            
            TextField("https://github.com/username/repository (Optional)", text: $remoteUrlInput)
                .font(.system(size: 13, design: .monospaced))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            
            HStack {
                Button(action: { step = 1 }) {
                    Text("← Back")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: fetchBranchesAndNext) {
                    HStack(spacing: 6) {
                        if isFetchingBranches {
                            ProgressView().controlSize(.small)
                            Text("Fetching Branches...")
                        } else {
                            Text("Next: Select Branch →")
                        }
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.85, green: 0.25, blue: 0.22))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
    }
    
    // STEP 3: BRANCH SELECTION
    @ViewBuilder
    private func renderStep3BranchSelection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 3: Choose Working Branch")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Select an existing branch pulled from GitHub or create a new one.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Color.white.opacity(0.6))
            
            if isCreatingNewBranch {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Branch Name")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                    
                    HStack {
                        TextField("feature/new-feature", text: $newBranchInput)
                            .font(.system(size: 13, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        
                        Button("Cancel") {
                            isCreatingNewBranch = false
                        }
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                        .buttonStyle(.plain)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(availableBranches, id: \.self) { bName in
                                Button(action: { selectedBranch = bName }) {
                                    HStack {
                                        Image(systemName: selectedBranch == bName ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedBranch == bName ? Color(red: 0.91, green: 0.29, blue: 0.25) : Color.white.opacity(0.3))
                                        Text(bName)
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(selectedBranch == bName ? Color.white.opacity(0.08) : Color.white.opacity(0.02))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 140)
                    
                    Button(action: { isCreatingNewBranch = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Create & Checkout New Branch")
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.91, green: 0.29, blue: 0.25))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            
            HStack {
                Button(action: { step = 2 }) {
                    Text("← Back")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: finishBranchSetup) {
                    Text("Confirm & Create Workspace →")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.85, green: 0.25, blue: 0.22))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
    }
    
    // STEP 4: IDE OPEN COMPLETION
    @ViewBuilder
    private func renderStep4IDECompletion() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.91, green: 0.29, blue: 0.25).opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.91, green: 0.29, blue: 0.25))
            }
            
            VStack(spacing: 4) {
                Text("Workspace Ready! 🎉")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Where would you like to open your project?")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Button(action: { gitService.openInIDE(.vscode, path: folderPath) }) {
                        HStack {
                            Text("🚀 VS Code")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { gitService.openInIDE(.cursor, path: folderPath) }) {
                        HStack {
                            Text("⚡️ Cursor")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 10) {
                    Button(action: { gitService.openInIDE(.antigravity, path: folderPath) }) {
                        HStack {
                            Text("⚛️ Antigravity")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { gitService.openInIDE(.terminal, path: folderPath) }) {
                        HStack {
                            Text("🧠 Terminal")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button(action: { gitService.showAddWorkspaceModal = false }) {
                Text("Done")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.85, green: 0.25, blue: 0.22))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }
    
    private func selectFolderWithPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            folderPath = url.path
        }
    }
    
    private func fetchBranchesAndNext() {
        isFetchingBranches = true
        Task {
            let branches = await gitService.fetchRemoteBranches(remoteUrl: remoteUrlInput, path: folderPath)
            availableBranches = branches
            if let first = branches.first {
                selectedBranch = first
            }
            isFetchingBranches = false
            step = 3
        }
    }
    
    private func finishBranchSetup() {
        let finalBranch = isCreatingNewBranch ? newBranchInput.trimmingCharacters(in: .whitespacesAndNewlines) : selectedBranch
        gitService.addWorkspace(path: folderPath, remoteUrl: remoteUrlInput, targetBranch: finalBranch.isEmpty ? "main" : finalBranch)
        step = 4
    }
}

#Preview {
    AddWorkspaceModalView()
        .environmentObject(GitService())
}
