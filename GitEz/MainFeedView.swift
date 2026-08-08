import SwiftUI

struct MainFeedView: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t

    @State private var newBranchInput  = ""
    @State private var showBranchAlert = false

    private var hasWorkspace: Bool {
        !gitService.workspaces.isEmpty && gitService.activeWorkspace != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if !hasWorkspace {
                emptyHero
            } else {
                // T3-style breadcrumb + action toolbar
                toolbar
                Rectangle().fill(t.divider).frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Step heading
                        VStack(spacing: 6) {
                            Text(stepHeading)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(t.textPrimary)
                                .multilineTextAlignment(.center)
                            Text(stepSubtitle)
                                .font(.system(size: 13))
                                .foregroundColor(t.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        // Step content
                        Group {
                            switch gitService.currentStep {
                            case .stage:               stageView
                            case .writeCommit, .commit: commitComposer
                            case .push:                pushView
                            case .openPR:              doneView
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 36)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .background(t.background)

                if gitService.showDiffViewer {
                    Rectangle().fill(t.divider).frame(height: 1)
                    CodeDiffView()
                        .environmentObject(gitService)
                        .environment(\.theme, t)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if gitService.showTerminalConsole {
                    Rectangle().fill(t.divider).frame(height: 1)
                    ConsoleLogView()
                        .environmentObject(gitService)
                        .environment(\.theme, t)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .background(t.background)
        .alert("New Branch", isPresented: $showBranchAlert) {
            TextField("branch-name", text: $newBranchInput)
            Button("Create & Checkout") {
                let n = newBranchInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !n.isEmpty { gitService.checkoutBranch(n); newBranchInput = "" }
            }
            Button("Cancel", role: .cancel) { newBranchInput = "" }
        } message: { Text("Enter a name for the new branch.") }
        .animation(.easeInOut(duration: 0.2), value: gitService.showDiffViewer)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Empty Hero (T3 style)
    // ─────────────────────────────────────────────────────────────
    private var emptyHero: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "#7C6BCF").opacity(0.35), radius: 24, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)

                VStack(spacing: 8) {
                    Text("What should we commit?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(t.textPrimary)

                    Text("Add a project to start tracking file changes\nand committing to GitHub.")
                        .font(.system(size: 14))
                        .foregroundColor(t.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                Button(action: { gitService.showAddWorkspaceModal = true }) {
                    HStack(spacing: 7) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        Text("Add project").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(LinearGradient(
                        colors: [t.accent, t.accentSecondary],
                        startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                    .shadow(color: t.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Background refresh hint
            HStack(spacing: 5) {
                Circle().fill(t.textTertiary).frame(width: 5, height: 5)
                Text("ZGit watches your files every 5 seconds — changes appear automatically.")
                    .font(.system(size: 11))
                    .foregroundColor(t.textTertiary)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - T3-Style Toolbar (breadcrumb + actions)
    // ─────────────────────────────────────────────────────────────
    private var toolbar: some View {
        HStack(spacing: 10) {
            // Breadcrumb
            HStack(spacing: 5) {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                    .foregroundColor(t.textTertiary)
                Text(gitService.activeWorkspace?.name ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(t.textSecondary)
                Text("/")
                    .font(.system(size: 13))
                    .foregroundColor(t.textTertiary)
                Text(stepLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(t.textPrimary)
            }

            // Tiny step dots
            HStack(spacing: 4) {
                ForEach(1...(gitService.autoOpenPROnPush ? 5 : 4), id: \.self) { n in
                    Circle()
                        .fill(n <= gitService.currentStep.rawValue ? t.accent : Color.white.opacity(0.15))
                        .frame(width: 5, height: 5)
                }
            }

            Spacer()

            // File change count indicator
            if !gitService.activeStatus.modifiedFiles.isEmpty {
                HStack(spacing: 5) {
                    Circle().fill(t.accent).frame(width: 6, height: 6)
                    Text("\(gitService.activeStatus.modifiedFiles.count) changed")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(t.textSecondary)
                }
            }

            // "Track changes from now" Toggle Button
            Button(action: {
                gitService.onlyChangesFromNow.toggle()
                if gitService.onlyChangesFromNow {
                    gitService.resetBaselineForCurrentWorkspace()
                } else {
                    gitService.refreshActiveStatus()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: gitService.onlyChangesFromNow ? "clock.badge.checkmark.fill" : "clock")
                        .font(.system(size: 10))
                    Text(gitService.onlyChangesFromNow ? "Changes from now" : "All files")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(gitService.onlyChangesFromNow ? t.accent : t.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(gitService.onlyChangesFromNow ? t.accentMuted : Color.white.opacity(0.06))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(
                    gitService.onlyChangesFromNow ? t.accent.opacity(0.4) : t.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(gitService.onlyChangesFromNow ? "Only tracking files modified since workspace was opened. Click to toggle all files." : "Tracking all modified/untracked files.")

            // Branch menu
            Menu {
                Section("Branches") {
                    ForEach(gitService.activeStatus.availableBranches) { b in
                        Button(action: { gitService.checkoutBranch(b.name) }) {
                            HStack {
                                if b.name == gitService.activeStatus.currentBranch { Image(systemName: "checkmark") }
                                Text(b.name)
                            }
                        }
                    }
                }
                Divider()
                Button(action: { showBranchAlert = true }) { Label("New branch…", systemImage: "plus") }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch").font(.system(size: 9, weight: .semibold))
                    Text(gitService.activeStatus.currentBranch.isEmpty ? "main" : gitService.activeStatus.currentBranch)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                    Image(systemName: "chevron.down").font(.system(size: 8))
                }
                .foregroundColor(t.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 1))
            }
            .menuStyle(.borderlessButton).fixedSize()

            // Diff toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    gitService.showDiffViewer.toggle()
                    if gitService.showDiffViewer { gitService.fetchDiff() }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.magnifyingglass").font(.system(size: 10))
                    Text("Diff").font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(gitService.showDiffViewer ? t.accent : t.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(gitService.showDiffViewer ? t.accentMuted : Color.white.opacity(0.06))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(
                    gitService.showDiffViewer ? t.accent.opacity(0.4) : t.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Debug Logs toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    gitService.showTerminalConsole.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "terminal").font(.system(size: 10))
                    Text("Debug Logs").font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(gitService.showTerminalConsole ? t.accent : t.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(gitService.showTerminalConsole ? t.accentMuted : Color.white.opacity(0.06))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(
                    gitService.showTerminalConsole ? t.accent.opacity(0.4) : t.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Primary action button (T3 "Push & create PR" style)
            if let label = toolbarActionLabel, let action = toolbarAction {
                Button(action: action) {
                    HStack(spacing: 5) {
                        Image(systemName: toolbarActionIcon ?? "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                        Text(label).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(LinearGradient(
                        colors: [t.accent, t.accentSecondary],
                        startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(7)
                    .shadow(color: t.accent.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(t.background)
    }

    private var stepLabel: String {
        switch gitService.currentStep {
        case .stage:                   return "Stage files"
        case .writeCommit, .commit:    return "Commit"
        case .push:                    return "Push"
        case .openPR:                  return "Done"
        }
    }

    private var toolbarActionLabel: String? {
        switch gitService.currentStep {
        case .stage:
            return gitService.selectedFilesToStage.isEmpty ? nil : "Stage \(gitService.selectedFilesToStage.count)"
        case .writeCommit, .commit:
            return gitService.commitMessage.isEmpty ? nil : "Commit"
        case .push:
            return "Push & create PR"
        case .openPR:
            return nil
        }
    }

    private var toolbarActionIcon: String? {
        switch gitService.currentStep {
        case .stage:              return "plus.square.on.square"
        case .writeCommit, .commit: return "checkmark"
        case .push:               return "arrow.up"
        case .openPR:             return nil
        }
    }

    private var toolbarAction: (() -> Void)? {
        switch gitService.currentStep {
        case .stage:
            return gitService.selectedFilesToStage.isEmpty ? nil : { gitService.executeStageFiles() }
        case .writeCommit, .commit:
            return gitService.commitMessage.isEmpty ? nil : { gitService.executeCommit() }
        case .push:
            return { Task { await gitService.executePush() } }
        case .openPR:
            return nil
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Step Headings
    // ─────────────────────────────────────────────────────────────
    private var stepHeading: String {
        let ws = gitService.activeWorkspace?.name ?? "project"
        switch gitService.currentStep {
        case .stage:                   return "What changed in \(ws)?"
        case .writeCommit, .commit:    return "Describe your changes"
        case .push:                    return "Push to GitHub"
        case .openPR:                  return "Changes pushed 🎉"
        }
    }

    private var stepSubtitle: String {
        switch gitService.currentStep {
        case .stage:                   return "Select the files to include in this commit."
        case .writeCommit, .commit:    return "Write a clear message so your future self understands."
        case .push:                    return "Send your commits to the remote repository."
        case .openPR:                  return "Your changes are live on GitHub."
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Step 1 · Stage
    // ─────────────────────────────────────────────────────────────
    private var stageView: some View {
        VStack(alignment: .leading, spacing: 14) {
            if gitService.activeStatus.modifiedFiles.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(t.accentMuted).frame(width: 44, height: 44)
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(t.accent)
                        }
                        Text("Working tree clean")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(t.textPrimary)
                        Text("ZGit is watching — no changes detected yet.")
                            .font(.system(size: 12))
                            .foregroundColor(t.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                // Select all header
                HStack {
                    Button(action: {
                        let all = Set(gitService.activeStatus.modifiedFiles)
                        gitService.selectedFilesToStage = gitService.selectedFilesToStage == all ? [] : all
                    }) {
                        HStack(spacing: 5) {
                            let allSel = gitService.selectedFilesToStage.count == gitService.activeStatus.modifiedFiles.count
                            Image(systemName: allSel ? "checkmark.square.fill" : "square")
                                .font(.system(size: 13))
                                .foregroundColor(allSel ? t.accent : t.textTertiary)
                            Text("Select all")
                                .font(.system(size: 12))
                                .foregroundColor(t.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("\(gitService.selectedFilesToStage.count) of \(gitService.activeStatus.modifiedFiles.count)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(t.textTertiary)
                }

                // File rows
                VStack(spacing: 2) {
                    ForEach(gitService.activeStatus.modifiedFiles, id: \.self) { file in
                        FileRow(file: file,
                                isChecked: gitService.selectedFilesToStage.contains(file)) {
                            if gitService.selectedFilesToStage.contains(file) {
                                gitService.selectedFilesToStage.remove(file)
                            } else {
                                gitService.selectedFilesToStage.insert(file)
                            }
                        }
                    }
                }

                // Stage button
                accentButton(
                    "Stage \(gitService.selectedFilesToStage.count) file\(gitService.selectedFilesToStage.count == 1 ? "" : "s")",
                    icon: "plus.square.on.square",
                    disabled: gitService.selectedFilesToStage.isEmpty
                ) { gitService.executeStageFiles() }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Step 2 · Commit Composer (T3 chat input style)
    // ─────────────────────────────────────────────────────────────
    private var commitComposer: some View {
        VStack(spacing: 0) {
            // Commit message area
            ZStack(alignment: .topLeading) {
                if gitService.commitMessage.isEmpty {
                    Text("Describe what changed in this commit…")
                        .font(.system(size: 14))
                        .foregroundColor(t.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.top, 15)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $gitService.commitMessage)
                    .font(.system(size: 14))
                    .foregroundColor(t.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .frame(minHeight: 100, maxHeight: 160)
            }

            // Quick prefix chips
            HStack(spacing: 6) {
                Text("Prefix:")
                    .font(.system(size: 11))
                    .foregroundColor(t.textTertiary)
                ForEach(["feat:", "fix:", "chore:", "docs:"], id: \.self) { p in
                    Button(p) {
                        if !gitService.commitMessage.hasPrefix(p) {
                            gitService.commitMessage = p + " " + gitService.commitMessage
                                .trimmingCharacters(in: .whitespaces)
                                .replacingOccurrences(of: "^\\w+: ?", with: "", options: .regularExpression)
                        }
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(t.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(5)
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Bottom bar (T3 chat composer footer)
            Rectangle().fill(t.divider).frame(height: 1)
            HStack(spacing: 10) {
                // Context info
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch").font(.system(size: 9))
                        Text(gitService.activeStatus.currentBranch.isEmpty ? "main" : gitService.activeStatus.currentBranch)
                            .font(.system(size: 11, design: .monospaced))
                    }
                    .foregroundColor(t.textTertiary)

                    if !gitService.activeStatus.modifiedFiles.isEmpty {
                        Rectangle().fill(t.divider).frame(width: 1, height: 14)
                        Text("\(gitService.activeStatus.modifiedFiles.count) file\(gitService.activeStatus.modifiedFiles.count == 1 ? "" : "s") staged")
                            .font(.system(size: 11))
                            .foregroundColor(t.textTertiary)
                    }
                }

                Spacer()

                // Back button
                Button(action: { gitService.currentStep = .stage }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(t.textTertiary)
                }
                .buttonStyle(.plain)

                // Commit submit button (T3-style circular send button)
                Button(action: { gitService.executeCommit() }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            gitService.commitMessage.trimmingCharacters(in: .whitespaces).isEmpty
                            ? LinearGradient(colors: [t.accent.opacity(0.4), t.accentSecondary.opacity(0.4)],
                                             startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [t.accent, t.accentSecondary],
                                             startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Circle())
                        .shadow(color: t.accent.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(gitService.commitMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(t.surface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 6)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Step 3 · Push
    // ─────────────────────────────────────────────────────────────
    private var pushView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Target branch")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(t.textSecondary)
                TextField("branch-name", text: $gitService.remoteBranch)
                    .font(.system(size: 13, design: .monospaced))
                    .textFieldStyle(.plain)
                    .foregroundColor(t.textPrimary)
                    .padding(12)
                    .background(t.surface)
                    .cornerRadius(9)
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(t.border, lineWidth: 1))
            }

            HStack(spacing: 10) {
                ghostButton("← Back") { gitService.currentStep = .writeCommit }

                if gitService.isExecuting {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Pushing…").font(.system(size: 13, weight: .semibold))
                            .foregroundColor(t.textSecondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(t.surfaceElevated).cornerRadius(9)
                } else {
                    accentButton("Push to origin/\(gitService.remoteBranch)", icon: "arrow.up") {
                        Task { await gitService.executePush() }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Step 4 · Done
    // ─────────────────────────────────────────────────────────────
    private var doneView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [t.accent, t.accentSecondary],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .shadow(color: t.accent.opacity(0.45), radius: 14, x: 0, y: 6)
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            HStack(spacing: 10) {
                ghostButton("← Back") { gitService.currentStep = .push }
                Button(action: { Task { await gitService.executeOpenPR() } }) {
                    HStack(spacing: 6) {
                        if gitService.isExecuting {
                            ProgressView().controlSize(.small)
                            Text("Opening…")
                        } else {
                            Image(systemName: "arrow.up.right.square").font(.system(size: 12))
                            Text("Open on GitHub")
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(LinearGradient(
                        colors: [t.accent, t.accentSecondary],
                        startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(9)
                    .shadow(color: t.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Shared UI Helpers
    // ─────────────────────────────────────────────────────────────
    @ViewBuilder
    private func accentButton(_ label: String, icon: String? = nil, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(disabled
                        ? LinearGradient(colors: [t.accent.opacity(0.35), t.accentSecondary.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [t.accent, t.accentSecondary], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(9)
            .shadow(color: disabled ? .clear : t.accent.opacity(0.3), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    @ViewBuilder
    private func ghostButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(t.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(9)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(t.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - File Row
// ─────────────────────────────────────────────────────────────────────────────
private struct FileRow: View {
    @Environment(\.theme) var t
    let file: String
    let isChecked: Bool
    let toggle: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 10) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14))
                    .foregroundColor(isChecked ? t.accent : t.textTertiary)

                Text(fileIcon(file))
                    .font(.system(size: 11))
                    .frame(width: 16)

                Text(file)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(t.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("M")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(t.accent)
                    .frame(width: 18, height: 18)
                    .background(t.accentMuted)
                    .cornerRadius(3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isChecked
                          ? t.accentMuted.opacity(0.3)
                          : (hovered ? Color.white.opacity(0.05) : t.surface))
            )
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(
                isChecked ? t.accent.opacity(0.2) : t.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }

    private func fileIcon(_ path: String) -> String {
        switch (path as NSString).pathExtension.lowercased() {
        case "swift":              return "◆"
        case "js", "ts", "jsx", "tsx": return "◇"
        case "json":               return "{}"
        case "md", "mdx":          return "¶"
        case "css", "scss":        return "◉"
        case "png", "jpg", "svg":  return "⬡"
        default:                   return "◻"
        }
    }
}

#Preview {
    MainFeedView()
        .environmentObject(GitService())
        .environment(\.theme, ThemeColors.make(.dark))
        .frame(width: 760, height: 680)
}
