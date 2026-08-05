import SwiftUI
import AppKit

struct AddWorkspaceModalView: View {
    @EnvironmentObject var gitService: GitService
    
    // Wizard Steps
    @State private var wizardStep: Int = 1 // 1: Folder, 2: Remote URL, 3: Branch Selection, 4: Launch IDE
    
    @State private var folderPathInput: String = ""
    @State private var remoteUrlInput: String = ""
    @State private var selectedBranchInput: String = "main"
    @State private var customBranchInput: String = ""
    @State private var isCreatingNewBranch: Bool = false
    
    @State private var fetchedBranches: [String] = ["main"]
    @State private var isFetchingBranches: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    if wizardStep < 4 {
                        gitService.showAddWorkspaceModal = false
                    }
                }
            
            // Glass Wizard Container
            VStack(alignment: .leading, spacing: 20) {
                // Header & Step Indicator
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        Text("Add New Workspace")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("STEP \(wizardStep) OF 4")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
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
                
                // STEP 1: SELECT LOCAL PROJECT FOLDER
                if wizardStep == 1 {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Step 1: Select your project directory")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Choose the local folder on your Mac where your codebase is located.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        HStack {
                            TextField("/Users/path/to/project", text: $folderPathInput)
                                .font(.system(size: 13, design: .monospaced))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                            
                            Button(action: selectFolder) {
                                Text("Browse...")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
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
                        
                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                        }
                        
                        Button(action: goToStep2) {
                            HStack {
                                Text("Next: Link Remote Repository →")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.25), Color(red: 0.08, green: 0.45, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }
                
                // STEP 2: LINK REMOTE GITHUB REPOSITORY
                else if wizardStep == 2 {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Step 2: Link Remote GitHub Repository")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Enter the remote GitHub URL for your project (or leave empty if local only).")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        TextField("https://github.com/username/repository (Optional)", text: $remoteUrlInput)
                            .font(.system(size: 13, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        HStack(spacing: 12) {
                            Button(action: { wizardStep = 1 }) {
                                Text("← Back")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                Task {
                                    await goToStep3()
                                }
                            }) {
                                HStack {
                                    if isFetchingBranches {
                                        ProgressView().controlSize(.small)
                                        Text("Pulling GitHub Branches...")
                                    } else {
                                        Text("Next: Select Branch →")
                                    }
                                }
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
                        }
                        .padding(.top, 8)
                    }
                }
                
                // STEP 3: SELECT OR CREATE BRANCH
                else if wizardStep == 3 {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Step 3: Select Working Branch")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Choose an available branch pulled from GitHub or create a new branch.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available Branches (\(fetchedBranches.count))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                            
                            ScrollView {
                                VStack(spacing: 6) {
                                    ForEach(fetchedBranches, id: \.self) { b in
                                        let isSelected = selectedBranchInput == b && !isCreatingNewBranch
                                        
                                        Button(action: {
                                            selectedBranchInput = b
                                            isCreatingNewBranch = false
                                        }) {
                                            HStack {
                                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(isSelected ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.3))
                                                
                                                Text(b)
                                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
                                                
                                                Spacer()
                                                
                                                if b == "main" || b == "master" {
                                                    Text("default")
                                                        .font(.system(size: 10, design: .rounded))
                                                        .foregroundColor(Color.white.opacity(0.4))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.white.opacity(0.08))
                                                        .cornerRadius(4)
                                                }
                                            }
                                            .padding(10)
                                            .background(isSelected ? Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2) : Color.white.opacity(0.03))
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(maxHeight: 140)
                        }
                        
                        // Create New Branch Toggle/Input
                        VStack(alignment: .leading, spacing: 6) {
                            Button(action: { isCreatingNewBranch.toggle() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isCreatingNewBranch ? "minus.circle.fill" : "plus.circle.fill")
                                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                                    Text(isCreatingNewBranch ? "Cancel New Branch" : "+ Create & Checkout New Branch")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                                }
                            }
                            .buttonStyle(.plain)
                            
                            if isCreatingNewBranch {
                                TextField("e.g. feature/auth-redesign", text: $customBranchInput)
                                    .font(.system(size: 13, design: .monospaced))
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.35, green: 0.85, blue: 0.5).opacity(0.5), lineWidth: 1)
                                    )
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { wizardStep = 2 }) {
                                Text("← Back")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: finishWorkspaceSetup) {
                                HStack {
                                    Text("Finish & Add Workspace →")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.25), Color(red: 0.08, green: 0.45, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 8)
                    }
                }
                
                // STEP 4: SUCCESS & OPEN IN IDE PROMPT
                else if wizardStep == 4 {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                                .frame(width: 64, height: 64)
                            Image(systemName: "checkmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        }
                        
                        VStack(spacing: 6) {
                            Text("Workspace Ready!")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Where would you like to open your workspace?")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                        
                        // IDE GRID BUTTONS
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                renderIDEButton(.vscode)
                                renderIDEButton(.cursor)
                            }
                            HStack(spacing: 10) {
                                renderIDEButton(.antigravity)
                                renderIDEButton(.terminal)
                            }
                        }
                        
                        Button(action: { gitService.showAddWorkspaceModal = false }) {
                            Text("Done & Return to GitEz")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .frame(width: 460)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    Color(red: 0.08, green: 0.1, blue: 0.13).opacity(0.92)
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
    
    // MARK: - Render IDE Launch Button
    @ViewBuilder
    private func renderIDEButton(_ ide: IDEApp) -> some View {
        Button(action: {
            gitService.openInIDE(ide, path: folderPathInput)
        }) {
            HStack(spacing: 10) {
                Image(systemName: ide.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                
                Text(ide.rawValue)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation Logic
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            self.folderPathInput = url.path
        }
    }
    
    private func goToStep2() {
        let path = folderPathInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.isEmpty {
            errorMessage = "Please select or enter a local project folder"
            return
        }
        
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: path, isDirectory: &isDir) || !isDir.boolValue {
            errorMessage = "Directory does not exist on disk"
            return
        }
        errorMessage = nil
        wizardStep = 2
    }
    
    private func goToStep3() async {
        isFetchingBranches = true
        let branches = await gitService.fetchRemoteBranches(remoteUrl: remoteUrlInput, path: folderPathInput)
        isFetchingBranches = false
        
        self.fetchedBranches = branches
        if let first = branches.first {
            self.selectedBranchInput = first
        }
        wizardStep = 3
    }
    
    private func finishWorkspaceSetup() {
        let targetBranch = isCreatingNewBranch ? customBranchInput.trimmingCharacters(in: .whitespacesAndNewlines) : selectedBranchInput
        let finalBranch = targetBranch.isEmpty ? "main" : targetBranch
        
        gitService.addWorkspace(path: folderPathInput, remoteUrl: remoteUrlInput, targetBranch: finalBranch)
        wizardStep = 4
    }
}

#Preview {
    AddWorkspaceModalView()
        .environmentObject(GitService())
}
