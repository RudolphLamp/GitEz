import SwiftUI
import AppKit

struct AddWorkspaceModalView: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t

    @State private var step: Int = 1
    @State private var folderPath         = ""
    @State private var remoteUrlInput     = ""
    @State private var isFetchingBranches = false
    @State private var availableBranches: [String] = []
    @State private var selectedBranch     = "main"
    @State private var newBranchInput     = ""
    @State private var isCreatingBranch   = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { gitService.showAddWorkspaceModal = false }

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 16))
                        .foregroundColor(t.accent)
                    Text("Add New Project")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(t.textPrimary)
                    Spacer()
                    // Step badge
                    Text("Step \(step) of 4")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(t.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(t.accentMuted)
                        .cornerRadius(6)
                    Button(action: { gitService.showAddWorkspaceModal = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(t.textTertiary)
                            .padding(6)
                            .background(t.surfaceElevated)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 18)

                // Step progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(t.border).frame(height: 2)
                        Rectangle()
                            .fill(t.accent)
                            .frame(width: geo.size.width * CGFloat(step) / 4.0, height: 2)
                            .animation(.easeInOut(duration: 0.3), value: step)
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Step content
                Group {
                    switch step {
                    case 1: step1FolderSelection
                    case 2: step2RemoteUrl
                    case 3: step3BranchPicker
                    case 4: step4Completion
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(width: 520)
            .background(t.surface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.border, lineWidth: 1))
        }
    }

    // MARK: Step 1 — Folder
    private var step1FolderSelection: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(title: "Select project folder",
                       subtitle: "Choose a local repository or project directory on your Mac.")

            HStack(spacing: 8) {
                TextField("/Users/you/Projects/MyRepo", text: $folderPath)
                    .font(.system(size: 13, design: .monospaced))
                    .textFieldStyle(.plain)
                    .foregroundColor(t.textPrimary)
                    .padding(10)
                    .background(t.surfaceElevated)
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 1))

                Button(action: selectFolder) {
                    Text("Browse…")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(t.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(t.surfaceElevated)
                        .cornerRadius(7)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            HStack {
                Spacer()
                nextButton(label: "Link remote repo  →", disabled: folderPath.isEmpty) { step = 2 }
            }
        }
    }

    // MARK: Step 2 — Remote URL
    private var step2RemoteUrl: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(title: "Link a GitHub repository",
                       subtitle: "Paste your GitHub repo URL. This is optional — you can add it later.")

            TextField("https://github.com/username/repo (optional)", text: $remoteUrlInput)
                .font(.system(size: 13, design: .monospaced))
                .textFieldStyle(.plain)
                .foregroundColor(t.textPrimary)
                .padding(10)
                .background(t.surfaceElevated)
                .cornerRadius(7)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 1))

            HStack {
                backButton { step = 1 }
                Spacer()
                Button(action: fetchBranchesAndNext) {
                    HStack(spacing: 6) {
                        if isFetchingBranches {
                            ProgressView().controlSize(.small)
                            Text("Fetching branches…")
                        } else {
                            Text("Choose branch  →")
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(t.accent)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isFetchingBranches)
            }
        }
    }

    // MARK: Step 3 — Branch
    private var step3BranchPicker: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(title: "Choose your working branch",
                       subtitle: "Select an existing branch or create a new one.")

            if isCreatingBranch {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New branch name")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(t.textSecondary)
                    HStack(spacing: 8) {
                        TextField("feature/my-feature", text: $newBranchInput)
                            .font(.system(size: 13, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(t.textPrimary)
                            .padding(10)
                            .background(t.surfaceElevated)
                            .cornerRadius(7)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 1))
                        Button("Cancel") { isCreatingBranch = false }
                            .font(.system(size: 12))
                            .foregroundColor(t.textSecondary)
                            .buttonStyle(.plain)
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(availableBranches, id: \.self) { bName in
                            Button(action: { selectedBranch = bName }) {
                                HStack(spacing: 10) {
                                    Image(systemName: selectedBranch == bName ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedBranch == bName ? t.accent : t.textTertiary)
                                    Text(bName)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(t.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(selectedBranch == bName ? t.accentMuted : t.surfaceElevated)
                                .cornerRadius(7)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 160)

                Button(action: { isCreatingBranch = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text("Create new branch…")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(t.accent)
                }
                .buttonStyle(.plain)
            }

            HStack {
                backButton { step = 2 }
                Spacer()
                nextButton(label: "Create workspace  →",
                           disabled: isCreatingBranch && newBranchInput.isEmpty) {
                    finishSetup()
                }
            }
        }
    }

    // MARK: Step 4 — Done
    private var step4Completion: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(t.accentMuted).frame(width: 56, height: 56)
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(t.accent)
                }
                Text("Project added! 🎉")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(t.textPrimary)
                Text("Open it in your preferred editor to start coding.")
                    .font(.system(size: 13))
                    .foregroundColor(t.textSecondary)
            }
            .frame(maxWidth: .infinity)

            // IDE launcher grid
            let ides: [(IDEApp, String, String)] = [
                (.vscode,       "VS Code",     "chevron.left.forwardslash.chevron.right"),
                (.cursor,       "Cursor",      "sparkles"),
                (.antigravity,  "Antigravity", "bolt.fill"),
                (.terminal,     "Terminal",    "terminal.fill")
            ]
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(ides, id: \.0) { ide, label, icon in
                    Button(action: { gitService.openInIDE(ide, path: folderPath) }) {
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 13))
                                .foregroundColor(t.textSecondary)
                            Text(label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(t.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(t.textTertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(t.surfaceElevated)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: { gitService.showAddWorkspaceModal = false }) {
                Text("Done")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(t.accent)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(t.textPrimary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(t.textSecondary)
        }
    }

    @ViewBuilder
    private func nextButton(label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(disabled ? t.accent.opacity(0.4) : t.accent)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    @ViewBuilder
    private func backButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left").font(.system(size: 10))
                Text("Back")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(t.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(t.surfaceElevated)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func selectFolder() {
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
            selectedBranch = branches.first ?? "main"
            isFetchingBranches = false
            step = 3
        }
    }

    private func finishSetup() {
        let branch = isCreatingBranch
            ? newBranchInput.trimmingCharacters(in: .whitespacesAndNewlines)
            : selectedBranch
        gitService.addWorkspace(path: folderPath, remoteUrl: remoteUrlInput,
                                targetBranch: branch.isEmpty ? "main" : branch)
        step = 4
    }
}

#Preview {
    AddWorkspaceModalView()
        .environmentObject(GitService())
        .environment(\.theme, ThemeColors.make(.dark))
}
