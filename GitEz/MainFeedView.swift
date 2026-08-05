import SwiftUI

struct MainFeedView: View {
    @EnvironmentObject var gitService: GitService
    
    @State private var newBranchInput: String = ""
    @State private var showNewBranchAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if gitService.workspaces.isEmpty || gitService.activeWorkspace == nil {
                renderEmptyWorkspaceHero()
            } else {
                // TOP BAR: CLEAN WORKSPACE PILLS & CONTROLS
                renderTopHeaderBar()
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // WORKSPACE TITLE & REAL BRANCH SELECTOR
                renderWorkspaceSubHeader()
                
                // MAIN FOCUSED STEPPER CONTAINER
                ScrollView {
                    VStack(spacing: 20) {
                        // SINGLE-STEP FOCUSED CARD
                        renderFocusedStepCard()
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
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
    
    // MARK: - Top Header Bar
    @ViewBuilder
    private func renderTopHeaderBar() -> some View {
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
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(isSelected ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.4))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isSelected ? Color(red: 0.35, green: 0.85, blue: 0.5).opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // AUTO PR SWITCH TOGGLE
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
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            
            // TERMINAL CONSOLE BUTTON
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
                        .cornerRadius(6)
                }
                .foregroundColor(gitService.showTerminalConsole ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(gitService.showTerminalConsole ? Color(red: 0.1, green: 0.3, blue: 0.18) : Color.white.opacity(0.06))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
    }
    
    // MARK: - Workspace Sub Header
    @ViewBuilder
    private func renderWorkspaceSubHeader() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Text(gitService.activeWorkspace?.name ?? "GitEz")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
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
                                .font(.system(size: 11, weight: .bold))
                            Text(gitService.activeStatus.currentBranch)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                        .cornerRadius(12)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
    }
    
    // MARK: - Single Focused Step Card with Circular Stepper Indicator
    @ViewBuilder
    private func renderFocusedStepCard() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // STEP CIRCULAR STEPPER INDICATOR HEADER
            renderCircularStepperHeader()
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // ACTIVE STEP CONTENT VIEW
            switch gitService.currentStep {
            case .stage:
                renderStep1StageView()
            case .writeCommit, .commit:
                renderStep2CommitView()
            case .push:
                renderStep3PushView()
            case .openPR:
                renderStep4PRView()
            }
        }
        .padding(28)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                Color(red: 0.08, green: 0.1, blue: 0.13).opacity(0.85)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
    }
    
    // MARK: - Circular Stepper Indicator
    @ViewBuilder
    private func renderCircularStepperHeader() -> some View {
        let totalSteps = gitService.autoOpenPROnPush ? 5 : 4
        
        HStack(spacing: 0) {
            ForEach(1...totalSteps, id: \.self) { stepNumber in
                let isCompleted = gitService.completedSteps.contains(WorkflowStep(rawValue: stepNumber)!)
                let isCurrent = gitService.currentStep.rawValue == stepNumber
                
                HStack(spacing: 0) {
                    // STEP CIRCLE BADGE
                    Button(action: {
                        if stepNumber < gitService.currentStep.rawValue {
                            if let targetStep = WorkflowStep(rawValue: stepNumber) {
                                gitService.currentStep = targetStep
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    isCompleted ? Color(red: 0.15, green: 0.75, blue: 0.35) :
                                    (isCurrent ? Color(red: 0.1, green: 0.55, blue: 0.25) : Color.white.opacity(0.08))
                                )
                                .frame(width: 36, height: 36)
                                .shadow(color: isCurrent ? Color(red: 0.35, green: 0.85, blue: 0.5).opacity(0.4) : Color.clear, radius: 8, x: 0, y: 2)
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(stepNumber)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(isCurrent ? .white : Color.white.opacity(0.4))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // CONNECTOR LINE
                    if stepNumber < totalSteps {
                        Rectangle()
                            .fill(
                                stepNumber < gitService.currentStep.rawValue ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.1)
                            )
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 1: Stage Files View
    @ViewBuilder
    private func renderStep1StageView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("STEP 1 OF \(gitService.autoOpenPROnPush ? 5 : 4)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        .tracking(1)
                    
                    Spacer()
                    
                    Text("\(gitService.activeStatus.modifiedFiles.count) Changed Files")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Text("Select files to include in your commit")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            
            if gitService.activeStatus.modifiedFiles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                    Text("Working tree clean!")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("No modified files detected on disk")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
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
                                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(isChecked ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.3))
                                
                                Text(file)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("MODIFIED")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.yellow)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.yellow.opacity(0.15))
                                    .cornerRadius(6)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Button(action: { gitService.executeStageFiles() }) {
                HStack(spacing: 8) {
                    Text("Stage \(gitService.selectedFilesToStage.count) Files & Next Step →")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color(red: 0.12, green: 0.65, blue: 0.3), Color(red: 0.08, green: 0.5, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color(red: 0.12, green: 0.65, blue: 0.3).opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Step 2: Write Commit View
    @ViewBuilder
    private func renderStep2CommitView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("STEP 2 OF \(gitService.autoOpenPROnPush ? 5 : 4)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                    .tracking(1)
                
                Text("Describe your changes")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Commit Message")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                
                TextField("e.g. fix: handle 401 session revocation and format sub-hour regular session defaults", text: $gitService.commitMessage)
                    .font(.system(size: 14, design: .rounded))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            
            // PRESET SUGGESTIONS
            HStack(spacing: 8) {
                Text("Quick Presets:")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.4))
                
                Button("fix: update UI") { gitService.commitMessage = "fix: update UI styling and layouts" }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .buttonStyle(.plain)
                
                Button("feat: add workflow") { gitService.commitMessage = "feat: add workflow step execution" }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .buttonStyle(.plain)
            }
            
            HStack(spacing: 14) {
                Button(action: {
                    gitService.currentStep = .stage
                }) {
                    Text("← Back")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                
                Button(action: { gitService.executeCommit() }) {
                    HStack {
                        Text("Commit Changes →")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color(red: 0.12, green: 0.65, blue: 0.3), Color(red: 0.08, green: 0.5, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0.12, green: 0.65, blue: 0.3).opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Step 3: Push to Remote View
    @ViewBuilder
    private func renderStep3PushView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("STEP 3 OF \(gitService.autoOpenPROnPush ? 5 : 4)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                    .tracking(1)
                
                Text("Push commits to GitHub")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Branch")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                
                TextField("branch-name", text: $gitService.remoteBranch)
                    .font(.system(size: 14, design: .monospaced))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            
            HStack(spacing: 14) {
                Button(action: {
                    gitService.currentStep = .writeCommit
                }) {
                    Text("← Back")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                
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
                        LinearGradient(colors: [Color(red: 0.12, green: 0.65, blue: 0.3), Color(red: 0.08, green: 0.5, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0.12, green: 0.65, blue: 0.3).opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Step 4: Open PR / Completion View
    @ViewBuilder
    private func renderStep4PRView() -> some View {
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
                Text("All Done! 🎉")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your commits have been pushed live to GitHub.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            HStack(spacing: 14) {
                Button(action: {
                    gitService.currentStep = .push
                }) {
                    Text("← Back")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    Task {
                        await gitService.executeOpenPR()
                    }
                }) {
                    HStack(spacing: 8) {
                        if gitService.isExecuting {
                            ProgressView().controlSize(.small)
                            Text("Preparing GitHub View...")
                        } else {
                            Image(systemName: "arrow.triangle.pull")
                            Text("View on GitHub 🚀")
                        }
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color(red: 0.12, green: 0.65, blue: 0.3), Color(red: 0.08, green: 0.5, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0.12, green: 0.65, blue: 0.3).opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
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
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(red: 0.12, green: 0.65, blue: 0.3).opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                        .cornerRadius(8)
                                }
                            }
                            .id(log.id)
                        }
                    }
                    .padding(12)
                }
                .frame(height: 180)
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
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
}

#Preview {
    MainFeedView()
        .environmentObject(GitService())
        .frame(width: 600, height: 600)
}
