import Foundation
import Combine
import AppKit

@MainActor
public class GitService: ObservableObject {
    @Published public var workspaces: [Workspace] = []
    @Published public var selectedWorkspaceID: UUID? = nil
    
    @Published public var gitUser: GitUser = GitUser(username: "", email: "", token: "")
    @Published public var activeStatus: GitStatusInfo = GitStatusInfo()
    @Published public var isExecuting: Bool = false
    @Published public var showSettingsModal: Bool = false
    @Published public var showAddWorkspaceModal: Bool = false
    @Published public var showHistoryModal: Bool = false
    @Published public var showTerminalConsole: Bool = false
    @Published public var showHistoryDrawer: Bool = false

    // Section navigation & diff viewer
    @Published public var currentSection: AppSection = .workspace
    @Published public var fileDiff: String = ""
    @Published public var showDiffViewer: Bool = false

    private var pollingTimer: Timer?
    
    // Auto Open PR Toggle
    @Published public var autoOpenPROnPush: Bool = true
    
    // Track only new changes toggle & baselines map
    @Published public var onlyChangesFromNow: Bool = true
    private var workspaceBaselines: [UUID: Date] = [:]
    
    public func resetBaselineForCurrentWorkspace() {
        if let ws = activeWorkspace {
            workspaceBaselines[ws.id] = Date()
            refreshActiveStatus()
        }
    }
    
    // Commit & Push History Log
    @Published public var commitHistory: [CommitLogItem] = []
    
    // Terminal Log History
    @Published public var terminalLogs: [TerminalLogEntry] = []
    
    // Workflow State
    @Published public var currentStep: WorkflowStep = .stage
    @Published public var completedSteps: Set<WorkflowStep> = []
    @Published public var feedItems: [FeedCardItem] = []
    
    // Step Form Inputs
    @Published public var selectedFilesToStage: Set<String> = []
    @Published public var commitMessage: String = "fix: handle 401 session revocation and format sub-hour regular session defaults"
    @Published public var remoteBranch: String = "main"
    
    private let savedWorkspacesKey = "gitez_saved_workspaces_v5"
    private let gitTokenKey = "gitez_github_token_v1"
    
    public var activeWorkspace: Workspace? {
        workspaces.first(where: { $0.id == selectedWorkspaceID })
    }
    
    public init() {
        loadSavedWorkspaces()
        fetchGitUser()
        startPolling()
    }
    
    // MARK: - IDE Launcher Helper
    public func openInIDE(_ ide: IDEApp, path: String? = nil) {
        let targetPath = path ?? activeWorkspace?.path ?? ""
        guard !targetPath.isEmpty else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        
        if ide == .finder {
            process.arguments = [targetPath]
        } else {
            process.arguments = ["-a", ide.appName, targetPath]
        }
        
        do {
            try process.run()
        } catch {
            print("Failed to open IDE: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Open Commit on GitHub
    public func openCommitOnGitHub(_ commitHash: String) {
        guard let ws = activeWorkspace else { return }
        let targetRemote = activeStatus.remoteUrl.isEmpty ? ws.remoteUrl : activeStatus.remoteUrl
        
        var commitUrlString = "https://github.com"
        if !targetRemote.isEmpty && targetRemote.contains("github.com") {
            let (cleanRemote, _) = GitService.sanitizeGitHubRemoteUrl(targetRemote)
            let baseRemote = cleanRemote
                .replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
                .replacingOccurrences(of: ".git", with: "")
            commitUrlString = "\(baseRemote)/commit/\(commitHash)"
        }
        
        if let url = URL(string: commitUrlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - GitHub Remote Branch Discovery
    public func fetchRemoteBranches(remoteUrl: String, path: String? = nil) async -> [String] {
        let (cleanRemote, _) = GitService.sanitizeGitHubRemoteUrl(remoteUrl)
        guard !cleanRemote.isEmpty else { return ["main"] }
        
        let args = ["ls-remote", "--heads", cleanRemote]
        if let p = path, !p.isEmpty {
            let res = runGitCommand(args, inDir: p)
            return parseLsRemoteOutput(res.output)
        } else {
            let res = runGitCommand(args)
            return parseLsRemoteOutput(res.output)
        }
    }
    
    private func parseLsRemoteOutput(_ rawOutput: String) -> [String] {
        var branches: [String] = []
        for line in rawOutput.components(separatedBy: .newlines) {
            if line.contains("refs/heads/") {
                let parts = line.components(separatedBy: "refs/heads/")
                if parts.count >= 2 {
                    let branchName = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !branchName.isEmpty && !branches.contains(branchName) {
                        branches.append(branchName)
                    }
                }
            }
        }
        return branches.isEmpty ? ["main"] : branches
    }
    
    // MARK: - GitHub URL Sanitizer Helper
    public static func sanitizeGitHubRemoteUrl(_ urlString: String) -> (cleanUrl: String, extractedBranch: String?) {
        var str = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        var branch: String? = nil
        
        if let range = str.range(of: "/tree/") {
            let branchPart = String(str[range.upperBound...])
            branch = branchPart.components(separatedBy: "/").first
            str = String(str[..<range.lowerBound])
        }
        if !str.hasSuffix(".git") && str.contains("github.com") {
            str += ".git"
        }
        return (str, branch)
    }
    
    // MARK: - Workspaces Management
    public func loadSavedWorkspaces() {
        if let data = UserDefaults.standard.data(forKey: savedWorkspacesKey),
           let decoded = try? JSONDecoder().decode([Workspace].self, from: data) {
            self.workspaces = decoded
            self.selectedWorkspaceID = decoded.first?.id
        } else {
            self.workspaces = []
            self.selectedWorkspaceID = nil
        }
        refreshActiveStatus()
    }
        // MARK: - Add Workspace (Folder / Worktree / Repo)
    public func addWorkspace(path: String, remoteUrl: String = "", targetBranch: String = "main") {
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let (cleanRemote, extractedBranch) = GitService.sanitizeGitHubRemoteUrl(remoteUrl)
        guard !cleanPath.isEmpty else { return }
        
        let folderName = (cleanPath as NSString).lastPathComponent
        let wsName = folderName.isEmpty ? "workspace" : folderName
        
        // Detect current branch of worktree if it already exists
        let currentBranchCheck = runGitCommand(["branch", "--show-current"], inDir: cleanPath, silent: true).output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalBranch: String
        if !currentBranchCheck.isEmpty {
            finalBranch = currentBranchCheck
        } else if let ext = extractedBranch {
            finalBranch = ext
        } else if !targetBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finalBranch = targetBranch.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            finalBranch = "main"
        }
        
        if let idx = workspaces.firstIndex(where: { $0.path == cleanPath }) {
            if !cleanRemote.isEmpty { workspaces[idx].remoteUrl = cleanRemote }
            workspaces[idx].selectedBranch = finalBranch
            selectedWorkspaceID = workspaces[idx].id
        } else {
            let newWs = Workspace(name: wsName, path: cleanPath, remoteUrl: cleanRemote, selectedBranch: finalBranch)
            workspaces.append(newWs)
            selectedWorkspaceID = newWs.id
        }
        
        saveWorkspaces()
        
        // Safely check repository/worktree status
        let isRepoCheck = runGitCommand(["rev-parse", "--is-inside-work-tree"], inDir: cleanPath, silent: true)
        let isGitDirCheck = runGitCommand(["rev-parse", "--git-dir"], inDir: cleanPath, silent: true)
        
        let isRepo = isRepoCheck.output.trimmingCharacters(in: .whitespacesAndNewlines) == "true" ||
                     !isGitDirCheck.output.contains("fatal:")
        
        if !isRepo {
            _ = runGitCommand(["init"], inDir: cleanPath, silent: true)
        }
        
        // Safely handle remote without destructive remove
        if !cleanRemote.isEmpty {
            let existingRemote = runGitCommand(["remote", "get-url", "origin"], inDir: cleanPath, silent: true).output.trimmingCharacters(in: .whitespacesAndNewlines)
            let isRemoteErr = existingRemote.contains("fatal:") || existingRemote.contains("error:") || existingRemote.contains("No such remote") || existingRemote.isEmpty
            if isRemoteErr {
                _ = runGitCommand(["remote", "add", "origin", cleanRemote], inDir: cleanPath, silent: true)
            } else if existingRemote != cleanRemote {
                _ = runGitCommand(["remote", "set-url", "origin", cleanRemote], inDir: cleanPath, silent: true)
            }
            _ = runGitCommand(["fetch", "origin"], inDir: cleanPath, silent: true)
        }
        
        // Checkout branch only if needed
        checkoutBranch(finalBranch)
        refreshActiveStatus()
    }
    
    public func removeWorkspace(id: UUID) {
        workspaces.removeAll(where: { $0.id == id })
        if selectedWorkspaceID == id {
            selectedWorkspaceID = workspaces.first?.id
        }
        saveWorkspaces()
        refreshActiveStatus()
    }
    
    private func saveWorkspaces() {
        if let encoded = try? JSONEncoder().encode(workspaces) {
            UserDefaults.standard.set(encoded, forKey: savedWorkspacesKey)
        }
    }
    
    // MARK: - Git Configuration Login & PAT Token
    public func fetchGitUser() {
        let nameOutput = runGitCommand(["config", "--global", "user.name"], silent: true).output
        let emailOutput = runGitCommand(["config", "--global", "user.email"], silent: true).output
        let savedToken = UserDefaults.standard.string(forKey: gitTokenKey) ?? ""
        
        let username = nameOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.gitUser = GitUser(username: username, email: email, token: savedToken)
    }
    
    public func saveGitUser(username: String, email: String, token: String = "") -> Bool {
        let cleanName = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        
        _ = runGitCommand(["config", "--global", "user.name", cleanName])
        _ = runGitCommand(["config", "--global", "user.email", cleanEmail])
        
        UserDefaults.standard.set(cleanToken, forKey: gitTokenKey)
        
        if !cleanToken.isEmpty {
            let authHeader = "Authorization: token \(cleanToken)"
            _ = runGitCommand(["config", "--global", "http.extraHeader", authHeader])
        }
        
        self.gitUser = GitUser(username: cleanName, email: cleanEmail, token: cleanToken)
        return true
    }
    
    // MARK: - Branch Checkout
    public func checkoutBranch(_ branchName: String) {
        guard let ws = activeWorkspace else { return }
        let dir = ws.path
        
        var target = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        if target.hasPrefix("remotes/origin/") {
            target = String(target.dropFirst("remotes/origin/".count))
        } else if target.hasPrefix("origin/") {
            target = String(target.dropFirst("origin/".count))
        }
        guard !target.isEmpty else { return }
        
        // Check current branch first - IF ALREADY ON TARGET BRANCH, DO NOTHING!
        let currentBranch = runGitCommand(["branch", "--show-current"], inDir: dir, silent: true).output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if currentBranch != target {
            // Check if local branch exists
            let checkLocal = runGitCommand(["rev-parse", "--verify", target], inDir: dir, silent: true)
            if !checkLocal.isError && !checkLocal.output.contains("fatal:") {
                _ = runGitCommand(["checkout", target], inDir: dir)
            } else {
                // Check if remote branch exists
                let checkRemote = runGitCommand(["rev-parse", "--verify", "origin/\(target)"], inDir: dir, silent: true)
                if !checkRemote.isError && !checkRemote.output.contains("fatal:") {
                    _ = runGitCommand(["checkout", "-b", target, "origin/\(target)"], inDir: dir)
                } else {
                    _ = runGitCommand(["checkout", "-b", target], inDir: dir)
                }
            }
        }
        
        if let idx = workspaces.firstIndex(where: { $0.id == ws.id }) {
            workspaces[idx].selectedBranch = target
            saveWorkspaces()
        }
        
        refreshActiveStatus()
    }
    
    // MARK: - Active Workspace Git Status & History Loading
    public func refreshActiveStatus() {
        guard let ws = activeWorkspace else {
            self.activeStatus = GitStatusInfo(isRepository: false)
            self.commitHistory = []
            return
        }
        
        let dir = ws.path
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else {
            self.activeStatus = GitStatusInfo(isRepository: false)
            self.commitHistory = []
            return
        }
        
        let isRepoCheck = runGitCommand(["rev-parse", "--is-inside-work-tree"], inDir: dir, silent: true)
        let isGitDirCheck = runGitCommand(["rev-parse", "--git-dir"], inDir: dir, silent: true)
        var isRepo = isRepoCheck.output.trimmingCharacters(in: .whitespacesAndNewlines) == "true" ||
                     !isGitDirCheck.output.contains("fatal:")
        
        if !isRepo {
            _ = runGitCommand(["init"], inDir: dir, silent: true)
            isRepo = true
        }
        
        let rawRemote = runGitCommand(["remote", "get-url", "origin"], inDir: dir, silent: true).output.trimmingCharacters(in: .whitespacesAndNewlines)
        let isRemoteErr = rawRemote.contains("fatal:") || rawRemote.contains("error:") || rawRemote.contains("No such remote") || rawRemote.isEmpty
        let validRemoteSrc = isRemoteErr ? ws.remoteUrl : rawRemote
        let (cleanRemote, _) = GitService.sanitizeGitHubRemoteUrl(validRemoteSrc.contains("error:") || validRemoteSrc.contains("fatal:") ? "" : validRemoteSrc)
        
        if !cleanRemote.isEmpty {
            if isRemoteErr {
                _ = runGitCommand(["remote", "add", "origin", cleanRemote], inDir: dir, silent: true)
            }
            _ = runGitCommand(["fetch", "origin"], inDir: dir, silent: true)
        }
        
        let branch = runGitCommand(["branch", "--show-current"], inDir: dir, silent: true).output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use --porcelain -uall to get exact file-level status and prevent listing top-level untracked directories
        let statusRaw = runGitCommand(["status", "--porcelain", "-uall"], inDir: dir, silent: true).output
        let lines = statusRaw.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var modified: [String] = []
        
        let baseline = self.workspaceBaselines[ws.id] ?? {
            let now = Date()
            self.workspaceBaselines[ws.id] = now
            return now
        }()
        
        let fm = FileManager.default
        
        for line in lines {
            guard line.count >= 3 else { continue }
            let statusCode = line.prefix(2)
            var rawFile = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            
            // Strip surrounding double quotes if present (git quotes paths containing spaces)
            if rawFile.hasPrefix("\"") && rawFile.hasSuffix("\"") && rawFile.count >= 2 {
                rawFile = String(rawFile.dropFirst().dropLast())
            }
            
            // Clean escaped characters
            rawFile = rawFile.replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
            
            if !rawFile.isEmpty &&
                !rawFile.hasPrefix(".DS_Store") &&
                !rawFile.hasPrefix(".git/") &&
                !rawFile.contains(".DS_Store") {
                if !rawFile.hasSuffix("/") {
                    if self.onlyChangesFromNow {
                        let fullPath = (dir as NSString).appendingPathComponent(rawFile)
                        if let attrs = try? fm.attributesOfItem(atPath: fullPath),
                           let modDate = attrs[.modificationDate] as? Date {
                            // Only include files modified AFTER baseline date (-1.0s clock tolerance)
                            if modDate > baseline.addingTimeInterval(-1.0) {
                                modified.append(rawFile)
                            }
                        } else if statusCode.contains("D") {
                            // Deleted file
                            modified.append(rawFile)
                        }
                    } else {
                        modified.append(rawFile)
                    }
                }
            }
        }
        
        let branchRaw = runGitCommand(["branch", "-a"], inDir: dir, silent: true).output
        var fetchedBranches: [GitBranch] = []
        var seenNames = Set<String>()
        
        for line in branchRaw.components(separatedBy: .newlines) {
            var name = line.trimmingCharacters(in: .whitespaces)
            let isCurrent = name.hasPrefix("* ")
            if isCurrent {
                name = String(name.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            }
            if name.contains("->") { continue }
            let isRemote = name.hasPrefix("remotes/")
            if isRemote {
                name = name.replacingOccurrences(of: "remotes/origin/", with: "")
                    .replacingOccurrences(of: "remotes/", with: "")
            }
            guard !name.isEmpty && !seenNames.contains(name) else { continue }
            seenNames.insert(name)
            fetchedBranches.append(GitBranch(name: name, isRemote: isRemote, isCurrent: isCurrent))
        }
        
        if fetchedBranches.isEmpty {
            fetchedBranches = [GitBranch(name: "main", isRemote: false, isCurrent: true)]
        }
        
        let finalBranch = branch.isEmpty ? (ws.selectedBranch.isEmpty ? "main" : ws.selectedBranch) : branch
        
        self.activeStatus = GitStatusInfo(
            isRepository: isRepo,
            currentBranch: finalBranch,
            modifiedFiles: modified,
            remoteUrl: cleanRemote,
            availableBranches: fetchedBranches
        )
        self.remoteBranch = finalBranch
        self.selectedFilesToStage = Set(self.activeStatus.modifiedFiles)
        
        if let idx = workspaces.firstIndex(where: { $0.id == ws.id }) {
            workspaces[idx].selectedBranch = finalBranch
            if !cleanRemote.isEmpty {
                workspaces[idx].remoteUrl = cleanRemote
            }
            saveWorkspaces()
        }
        
        loadCommitHistory(inDir: dir)
        
        if self.feedItems.isEmpty {
            self.feedItems = [
                FeedCardItem(type: .info("Workspace opened\n\(dir) on \(finalBranch)")),
                FeedCardItem(type: .filesDetected(modified))
            ]
        }
    }
    
    private func loadCommitHistory(inDir: String) {
        let logRaw = runGitCommand(["log", "-n", "25", "--pretty=format:%H|%h|%s|%an|%cr"], inDir: inDir).output
        
        if logRaw.contains("fatal:") || logRaw.contains("does not have any commits") {
            self.commitHistory = []
            return
        }
        
        var items: [CommitLogItem] = []
        
        for line in logRaw.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: "|")
            if parts.count >= 5 {
                let item = CommitLogItem(
                    hash: parts[0],
                    shortHash: parts[1],
                    message: parts[2],
                    author: parts[3],
                    dateString: parts[4]
                )
                items.append(item)
            }
        }
        self.commitHistory = items
    }
    
    // MARK: - Workflow Execution Steps
    private func checkForConflictMarkers(inDir: String) -> [String] {
        let diffCheck = runGitCommand(["diff", "--check"], inDir: inDir, silent: true)
        if diffCheck.output.contains("leftover conflict marker") {
            var filesWithConflicts: [String] = []
            for line in diffCheck.output.components(separatedBy: .newlines) {
                if line.contains("leftover conflict marker") {
                    let parts = line.components(separatedBy: ":")
                    if let filename = parts.first?.trimmingCharacters(in: .whitespaces), !filename.isEmpty {
                        filesWithConflicts.append(filename)
                    }
                }
            }
            return Array(Set(filesWithConflicts))
        }
        return []
    }

    public func executeStageFiles() {
        guard let ws = activeWorkspace else { return }
        let dir = ws.path
        let files = Array(selectedFilesToStage)
        
        let conflicts = checkForConflictMarkers(inDir: dir)
        if !conflicts.isEmpty {
            feedItems.append(FeedCardItem(type: .pushError("Cannot stage: Conflict markers detected in \(conflicts.joined(separator: ", "))")))
            return
        }
        
        if files.isEmpty || files.count == activeStatus.modifiedFiles.count {
            _ = runGitCommand(["add", "."], inDir: dir)
        } else {
            for f in files {
                _ = runGitCommand(["add", f], inDir: dir)
            }
        }
        
        completedSteps.insert(.stage)
        completedSteps.insert(.writeCommit)
        feedItems.append(FeedCardItem(type: .stagedSuccess(files.isEmpty ? activeStatus.modifiedFiles.count : files.count, files.isEmpty ? activeStatus.modifiedFiles : files)))
        currentStep = .commit
    }
    
    public func executeCommit() {
        guard let ws = activeWorkspace else { return }
        let dir = ws.path
        let msg = commitMessage.isEmpty ? "Update project changes" : commitMessage
        
        let conflicts = checkForConflictMarkers(inDir: dir)
        if !conflicts.isEmpty {
            feedItems.append(FeedCardItem(type: .pushError("Cannot commit: Conflict markers (<<<<<<< HEAD) detected in \(conflicts.joined(separator: ", "))")))
            return
        }
        
        _ = runGitCommand(["add", "."], inDir: dir)
        let commitRes = runGitCommand(["commit", "-m", msg], inDir: dir)
        
        if commitRes.isError && (commitRes.output.contains("error:") || commitRes.output.contains("fatal:")) {
            feedItems.append(FeedCardItem(type: .pushError(commitRes.output)))
            return
        }
        
        let count = selectedFilesToStage.isEmpty ? max(1, activeStatus.modifiedFiles.count) : selectedFilesToStage.count
        
        completedSteps.insert(.commit)
        feedItems.append(FeedCardItem(type: .commitSuccess(msg, count, activeStatus.currentBranch)))
        loadCommitHistory(inDir: dir)
        currentStep = .push
    }
    
    public func executePush() async {
        guard let ws = activeWorkspace else { return }
        let dir = ws.path
        let branch = remoteBranch.isEmpty ? activeStatus.currentBranch : remoteBranch
        
        isExecuting = true
        feedItems.append(FeedCardItem(type: .pushing(branch)))
        
        let rawTarget = activeStatus.remoteUrl.isEmpty ? ws.remoteUrl : activeStatus.remoteUrl
        let isInvalid = rawTarget.contains("error:") || rawTarget.contains("fatal:") || rawTarget.isEmpty
        let validRemote = isInvalid ? ws.remoteUrl : rawTarget
        
        if !validRemote.isEmpty && !validRemote.contains("error:") && !validRemote.contains("fatal:") {
            let (cleanRemote, _) = GitService.sanitizeGitHubRemoteUrl(validRemote)
            let existingRemote = runGitCommand(["remote", "get-url", "origin"], inDir: dir, silent: true).output.trimmingCharacters(in: .whitespacesAndNewlines)
            if existingRemote.contains("fatal:") || existingRemote.contains("error:") || existingRemote.isEmpty {
                _ = runGitCommand(["remote", "add", "origin", cleanRemote], inDir: dir)
            } else if existingRemote != cleanRemote {
                _ = runGitCommand(["remote", "set-url", "origin", cleanRemote], inDir: dir)
            }
        }
        
        let pushResult = runGitCommand(["push", "-u", "origin", branch], inDir: dir)
        isExecuting = false
        
        if pushResult.isError || pushResult.output.contains("rejected") || pushResult.output.contains("fatal:") || pushResult.output.contains("error:") {
            feedItems.append(FeedCardItem(type: .pushError(pushResult.output)))
        } else {
            completedSteps.insert(.push)
            feedItems.append(FeedCardItem(type: .pushSuccess(branch)))
            loadCommitHistory(inDir: dir)
            
            if autoOpenPROnPush {
                currentStep = .openPR
            } else {
                completedSteps.insert(.openPR)
                feedItems.append(FeedCardItem(type: .completedAll))
            }
        }
    }
    
    public func executeOpenPR() async {
        isExecuting = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isExecuting = false
        completedSteps.insert(.openPR)
        
        let targetRemote = activeStatus.remoteUrl.isEmpty ? activeWorkspace?.remoteUrl ?? "" : activeStatus.remoteUrl
        var prUrlString = "https://github.com"
        let branch = remoteBranch.isEmpty ? activeStatus.currentBranch : remoteBranch
        
        if !targetRemote.isEmpty && targetRemote.contains("github.com") {
            let (cleanRemote, _) = GitService.sanitizeGitHubRemoteUrl(targetRemote)
            let baseRemote = cleanRemote
                .replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
                .replacingOccurrences(of: ".git", with: "")
            
            if branch == "main" || branch == "master" {
                prUrlString = baseRemote
            } else {
                prUrlString = "\(baseRemote)/compare/main...\(branch)?expand=1"
            }
        }
        
        feedItems.append(FeedCardItem(type: .prSuccess(prUrlString)))
        feedItems.append(FeedCardItem(type: .completedAll))
        
        if let url = URL(string: prUrlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Diff Fetching
    public func fetchDiff() {
        guard let ws = activeWorkspace else { fileDiff = ""; return }
        let result = runGitCommand(["diff", "HEAD"], inDir: ws.path, silent: true)
        self.fileDiff = result.isError ? "" : result.output
    }

    // MARK: - Background Polling (5-second auto-refresh)
    public func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.refreshActiveStatus()
                if self.showDiffViewer { self.fetchDiff() }
            }
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    public func clearTerminalLogs() {
        terminalLogs.removeAll()
    }
    
    // MARK: - Process Execution Helper
    @discardableResult
    private func runGitCommand(_ arguments: [String], inDir: String? = nil, silent: Bool = false) -> (output: String, isError: Bool) {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        if let dir = inDir, !dir.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
        }
        
        if !gitUser.token.isEmpty {
            var env = ProcessInfo.processInfo.environment
            env["GIT_TERMINAL_PROMPT"] = "0"
            process.environment = env
        }
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        var outputText = ""
        var isErr = false
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            outputText = String(data: data, encoding: .utf8) ?? ""
            isErr = process.terminationStatus != 0 || outputText.contains("fatal:") || outputText.contains("error:")
        } catch {
            outputText = "Execution failed: \(error.localizedDescription)"
            isErr = true
        }
        
        let fullCmd = "git " + arguments.joined(separator: " ")
        let logEntry = TerminalLogEntry(command: fullCmd, output: outputText.trimmingCharacters(in: .whitespacesAndNewlines), isError: isErr)
        terminalLogs.append(logEntry)
        if terminalLogs.count > 120 {
            terminalLogs.removeFirst(terminalLogs.count - 120)
        }
        
        return (outputText, isErr)
    }
}
