import SwiftUI

struct MainFeedView: View {
    @EnvironmentObject var gitService: GitService
    
    @State private var newBranchInput: String = ""
    @State private var showNewBranchAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if gitService.workspaces.isEmpty || gitService.activeWorkspace == nil {
                // EMPTY WORKSPACE WELCOME HERO SCREEN
                renderEmptyWorkspaceHero()
            } else {
                // WORKSPACE PILL TABS TOP BAR
                HStack(spacing: 12) {
                    ForEach(gitService.workspaces) { ws in
                        let isSelected = gitService.selectedWorkspaceID == ws.id
                        
                        Button(action: {
                            gitService.selectedWorkspaceID = ws.id
                            gitService.refreshActiveStatus()
                        }) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(isSelected ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                
                                Text(ws.name)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                                
                                Text(isSelected ? "\(gitService.completedSteps.count)/\(gitService.autoOpenPROnPush ? 5 : 4)" : "0/\(gitService.autoOpenPROnPush ? 5 : 4)")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(isSelected ? Color.white.opacity(0.8) : Color.white.opacity(0.4))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // TOP BAR PR TOGGLE BUTTON
                    Toggle(isOn: $gitService.autoOpenPROnPush) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.triangle.pull")
                                .font(.system(size: 10, weight: .bold))
                            Text("Auto PR")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(gitService.autoOpenPROnPush ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.5))
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                    
                    // TERMINAL CONSOLE TOGGLE BUTTON
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            gitService.showTerminalConsole.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 11))
                            Text("Terminal Console")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Text("\(gitService.terminalLogs.count)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.25))
                                .cornerRadius(4)
                        }
                        .foregroundColor(gitService.showTerminalConsole ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(gitService.showTerminalConsole ? Color(red: 0.1, green: 0.3, blue: 0.18) : Color.white.opacity(0.06))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // ACTIVE WORKSPACE TITLE HEADER BAR WITH REAL BRANCH SELECTOR
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            Text(gitService.activeWorkspace?.name ?? "GitEz")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            
                            // REAL GIT BRANCH SELECTOR MENU
                            Menu {
                                Section("Local & Remote Branches") {
                                    ForEach(gitService.activeStatus.availableBranches) { b in
                                        Button(action: {
                                            gitService.checkoutBranch(b.name)
                                        }) {
                                            HStack {
                                                if b.name == gitService.activeStatus.currentBranch {
                                                    Image(systemName: "checkmark")
                                                }
                                                Text(b.name)
                                            }
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                Button(action: { showNewBranchAlert = true }) {
                                    Label("Create New Branch...", systemImage: "plus")
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.pull")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(gitService.activeStatus.currentBranch)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                                .cornerRadius(6)
                            }
                            .menuStyle(.borderlessButton)
                        }
                        
                        Text(gitService.activeWorkspace?.path ?? "~/Projects")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    Text("@\(gitService.gitUser.username.isEmpty ? "rudolph" : gitService.gitUser.username)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                
                // COMMIT HISTORY DRAWER OVERLAY
                if gitService.showHistoryDrawer {
                    renderCommitHistoryDrawer()
                }
                
                // FEED CARDS SCROLL VIEW
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(gitService.feedItems) { item in
                            renderFeedCard(item)
                        }
                        
                        renderActiveStepCard()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                // EMBEDDED REAL TERMINAL CONSOLE DRAWER
                if gitService.showTerminalConsole {
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.white.opacity(0.12))
                        
                        renderTerminalConsoleDrawer()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .alert("Create New Branch", isPresented: $showNewBranchAlert) {
            TextField("branch-name", text: $newBranchInput)
            Button("Create & Checkout") {
                let name = newBranchInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    gitService.checkoutBranch(name)
                    newBranchInput = ""
                }
            }
            Button("Cancel", role: .cancel) { newBranchInput = "" }
        } message: {
            Text("Enter a name for the new branch to create and checkout.")
        }
    }
    
    // MARK: - Empty Workspace Hero Screen
    @ViewBuilder
    private func renderEmptyWorkspaceHero() -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.15, green: 0.8, blue: 0.4), Color(red: 0.08, green: 0.55, blue: 0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Welcome to GitEz")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Effortless GitHub commits and step-by-step workflow")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    gitService.showAddWorkspaceModal = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add Your First Workspace")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.12, green: 0.65, blue: 0.3), Color(red: 0.08, green: 0.5, blue: 0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0.12, green: 0.65, blue: 0.3).opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - GitHub Commit & Push History Drawer Panel
    @ViewBuilder
    private func renderCommitHistoryDrawer() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                    
                    Text("GITHUB COMMIT & PUSH HISTORY")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: { gitService.showHistoryDrawer = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            
            if gitService.commitHistory.isEmpty {
                Text("No commits recorded yet in this workspace.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(18)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(gitService.commitHistory) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Text(item.shortHash)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                                    .cornerRadius(6)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.message)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 6) {
                                        Text(item.author)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(Color.white.opacity(0.5))
                                        
                                        Text("·")
                                            .foregroundColor(Color.white.opacity(0.3))
                                        
                                        Text(item.dateString)
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundColor(Color.white.opacity(0.4))
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
                }
                .frame(maxHeight: 220)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
        .background(Color(red: 0.07, green: 0.09, blue: 0.12))
    }
    
    // MARK: - Terminal Console Drawer View
    @ViewBuilder
    private func renderTerminalConsoleDrawer() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                    Text("TERMINAL CLI CONSOLE OUTPUT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: {
                    let logText = gitService.terminalLogs.map { "[\($0.timestamp.formatted(date: .omitted, time: .standard))] $ \($0.command)\n\($0.output)" }.joined(separator: "\n\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(logText, forType: .string)
                }) {
                    Text("Copy All")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(gitService.terminalLogs.isEmpty)
                
                Button(action: { gitService.clearTerminalLogs() }) {
                    Text("Clear")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: { gitService.showTerminalConsole = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(gitService.terminalLogs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(log.timestamp, style: .time)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.3))
                                    
                                    Text("$ \(log.command)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(log.isError ? Color(red: 0.95, green: 0.4, blue: 0.4) : Color(red: 0.4, green: 0.85, blue: 0.5))
                                }
                                
                                if !log.output.isEmpty {
                                    Text(log.output)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(log.isError ? Color(red: 0.95, green: 0.6, blue: 0.6) : Color.white.opacity(0.8))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(6)
                                }
                            }
                            .id(log.id)
                        }
                    }
                    .padding(12)
                }
                .frame(height: 180)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .onChange(of: gitService.terminalLogs.count) { _ in
                    if let last = gitService.terminalLogs.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(red: 0.08, green: 0.1, blue: 0.12))
    }
    
    // MARK: - Feed Card Item Renderer
    @ViewBuilder
    private func renderFeedCard(_ item: FeedCardItem) -> some View {
        switch item.type {
        case .info(let text):
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Text("i")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                }
                
                Text(text)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.9))
                
                Spacer()
                
                Text(item.timestamp, style: .time)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            
        case .filesDetected(let files):
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Text("i")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(files.count) changed files detected")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(files.joined(separator: " · "))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                Text(item.timestamp, style: .time)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            
        case .stepActive(_):
            EmptyView()
            
        case .stagedSuccess(let count, let files):
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Staged all \(count) files")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(files.joined(separator: " · "))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                Text(item.timestamp, style: .time)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(14)
            .background(Color(red: 0.1, green: 0.3, blue: 0.18).opacity(0.3))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.4), lineWidth: 1)
            )
            
        case .commitSuccess(let msg, let count, let branch):
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Committed: \"\(msg)\"")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(count) files · \(branch)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                Text(item.timestamp, style: .time)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(14)
            .background(Color(red: 0.1, green: 0.3, blue: 0.18).opacity(0.3))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.4), lineWidth: 1)
            )
            
        case .pushing(let branch):
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 24, height: 24)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pushing to origin/\(branch)...")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Contacting GitHub")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                Text(item.timestamp, style: .time)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            
        case .pushSuccess(let branch):
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pushed to origin/\(branch)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Remote updated successfully")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                Text(item.timestamp, style: .time)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(14)
            .background(Color(red: 0.1, green: 0.3, blue: 0.18).opacity(0.3))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.4), lineWidth: 1)
            )
            
        case .pushError(let errMessage):
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Push Failed")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.4, blue: 0.4))
                    
                    Text(errMessage)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    gitService.showTerminalConsole = true
                }) {
                    Text("Inspect Console")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.red.opacity(0.12))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.4), lineWidth: 1)
            )
            
        case .prSuccess(let prUrl):
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: "arrow.triangle.pull")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prUrl.contains("/compare/") ? "Created Branch PR Comparison" : "Pushed to Repository")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(prUrl)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(14)
            .background(Color(red: 0.1, green: 0.3, blue: 0.18).opacity(0.3))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.4), lineWidth: 1)
            )
            
        case .completedAll:
            VStack(spacing: 12) {
                Text("🎉")
                    .font(.system(size: 32))
                
                Text("All done!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                
                Text("Your code is pushed and live on GitHub.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.08, green: 0.22, blue: 0.14).opacity(0.5))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Active Step Interactive Card
    @ViewBuilder
    private func renderActiveStepCard() -> some View {
        if !gitService.completedSteps.contains(.openPR) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("STEP \(gitService.currentStep.rawValue) · \(gitService.currentStep.title.uppercased())")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        .tracking(1)
                    
                    Spacer()
                }
                
                Text(gitService.currentStep.subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
                
                switch gitService.currentStep {
                case .stage:
                    VStack(spacing: 8) {
                        ForEach(gitService.activeStatus.modifiedFiles, id: \.self) { file in
                            let isChecked = gitService.selectedFilesToStage.contains(file)
                            
                            Button(action: {
                                if isChecked {
                                    gitService.selectedFilesToStage.remove(file)
                                } else {
                                    gitService.selectedFilesToStage.insert(file)
                                }
                            }) {
                                HStack {
                                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 16))
                                        .foregroundColor(isChecked ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.3))
                                    
                                    Text(file)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("M")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.yellow)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.yellow.opacity(0.15))
                                        .cornerRadius(4)
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Button(action: { gitService.executeStageFiles() }) {
                        HStack {
                            Text("Stage all \(gitService.selectedFilesToStage.count) files →")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.25), Color(red: 0.08, green: 0.45, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                case .commit, .writeCommit:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Commit Message")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        TextField("e.g. fix: handle 401 session revocation", text: $gitService.commitMessage)
                            .font(.system(size: 14, design: .rounded))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        
                        Button(action: { gitService.executeCommit() }) {
                            HStack {
                                Text("Commit \(gitService.selectedFilesToStage.count) files →")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.25), Color(red: 0.08, green: 0.45, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    
                case .push:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target Branch")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        TextField("branch-name", text: $gitService.remoteBranch)
                            .font(.system(size: 14, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        
                        Button(action: {
                            Task {
                                await gitService.executePush()
                            }
                        }) {
                            HStack {
                                if gitService.isExecuting {
                                    ProgressView().controlSize(.small)
                                    Text("Pushing to origin/\(gitService.remoteBranch)...")
                                } else {
                                    Text("Push to origin/\(gitService.remoteBranch) →")
                                }
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.25), Color(red: 0.08, green: 0.45, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    
                case .openPR:
                    Button(action: {
                        Task {
                            await gitService.executeOpenPR()
                        }
                    }) {
                        HStack(spacing: 10) {
                            if gitService.isExecuting {
                                ProgressView().controlSize(.small)
                                Text("Preparing Pull Request on GitHub...")
                            } else {
                                Image(systemName: "arrow.triangle.pull")
                                Text(gitService.remoteBranch == "main" ? "View Code on GitHub 🚀" : "Open Pull Request on GitHub 🚀")
                            }
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.25), Color(red: 0.08, green: 0.45, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.4), lineWidth: 1.2)
            )
        }
    }
}

#Preview {
    MainFeedView()
        .environmentObject(GitService())
        .frame(width: 600, height: 600)
}
