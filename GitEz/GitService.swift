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
    @Published public var showTerminalConsole: Bool = false
    
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
    
    private let savedWorkspacesKey = "gitez_saved_workspaces_v3"
    private let gitTokenKey = "gitez_github_token_v1"
    
    public var activeWorkspace: Workspace? {
        workspaces.first(where: { $0.id == selectedWorkspaceID })
    }
    
    public init() {
        loadSavedWorkspaces()
        fetchGitUser()
    }
    
    // MARK: - Workspaces Management
    public func loadSavedWorkspaces() {
        if let data = UserDefaults.standard.data(forKey: savedWorkspacesKey),
           let decoded = try? JSONDecoder().decode([Workspace].self, from: data), !decoded.isEmpty {
            self.workspaces = decoded
            self.selectedWorkspaceID = decoded.first?.id
        } else {
            let currentPath = FileManager.default.currentDirectoryPath
            let name = (currentPath as NSString).lastPathComponent
            let defaultWs = Workspace(
                name: name.isEmpty ? "GitEz" : name,
                path: currentPath,
                remoteUrl: "https://github.com/COS301-SE-2026/Cybersecurity-Awareness-Training-Platform",
                selectedBranch: "main"
            )
            self.workspaces = [defaultWs]
            self.selectedWorkspaceID = defaultWs.id
            saveWorkspaces()
        }
        refreshActiveStatus()
    }
    
    public func addWorkspace(path: String, remoteUrl: String) {
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanRemote = remoteUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPath.isEmpty else { return }
        
        let folderName = (cleanPath as NSString).lastPathComponent
        let wsName = folderName.isEmpty ? "workspace" : folderName
        
        if let idx = workspaces.firstIndex(where: { $0.path == cleanPath }) {
            workspaces[idx].remoteUrl = cleanRemote
            selectedWorkspaceID = workspaces[idx].id
        } else {
            let newWs = Workspace(name: wsName, path: cleanPath, remoteUrl: cleanRemote)
            workspaces.append(newWs)
            selectedWorkspaceID = newWs.id
        }
        
        saveWorkspaces()
        
        // Initialize git repo if not already initialized
        let isRepoCheck = runGitCommand(["rev-parse", "--is-inside-work-tree"], inDir: cleanPath)
        if isRepoCheck.output.trimmingCharacters(in: .whitespacesAndNewlines) != "true" {
            _ = runGitCommand(["init"], inDir: cleanPath)
        }
        
        // Link remote origin if remoteUrl provided
        if !cleanRemote.isEmpty {
            _ = runGitCommand(["remote", "remove", "origin"], inDir: cleanPath)
            _ = runGitCommand(["remote", "add", "origin", cleanRemote], inDir: cleanPath)
        }
        
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
        let nameOutput = runGitCommand(["config", "--global", "user.name"]).output
        let emailOutput = runGitCommand(["config", "--global", "user.email"]).output
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
        
        var target = branchName
        if target.hasPrefix("remotes/origin/") {
            target = String(target.dropFirst("remotes/origin/".count))
        } else if target.hasPrefix("origin/") {
            target = String(target.dropFirst("origin/".count))
        }
        
        let res = runGitCommand(["checkout", target], inDir: dir)
        if res.isError {
            _ = runGitCommand(["checkout", "-b", target], inDir: dir)
        }
        
        if let idx = workspaces.firstIndex(where: { $0.id == ws.id }) {
            workspaces[idx].selectedBranch = target
            saveWorkspaces()
        }
        
        refreshActiveStatus()
    }
    
    // MARK: - Active Workspace Git Status
    public func refreshActiveStatus() {
        guard let ws = activeWorkspace else {
            self.activeStatus = GitStatusInfo(isRepository: false)
            return
        }
        
        let dir = ws.path
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else {
            self.activeStatus = GitStatusInfo(isRepository: false)
            return
        }
        
        let isRepoCheck = runGitCommand(["rev-parse", "--is-inside-work-tree"], inDir: dir)
        var isRepo = isRepoCheck.output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
        
        if !isRepo {
            _ = runGitCommand(["init"], inDir: dir)
            isRepo = true
        }
        
        let branch = runGitCommand(["branch", "--show-current"], inDir: dir).output.trimmingCharacters(in: .whitespacesAndNewlines)
        let remote = runGitCommand(["remote", "get-url", "origin"], inDir: dir).output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let statusRaw = runGitCommand(["status", "--untracked-files=all", "--short"], inDir: dir).output
        let lines = statusRaw.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var modified = lines.map { String($0.dropFirst(3)).trimmingCharacters(in: .whitespaces) }
        
        if modified.isEmpty {
            if let filesOnDisk = try? FileManager.default.contentsOfDirectory(atPath: dir) {
                let nonGitFiles = filesOnDisk.filter { !$0.hasPrefix(".") && $0 != "node_modules" }
                if !nonGitFiles.isEmpty {
                    modified = nonGitFiles
                }
            }
        }
        
        let branchRaw = runGitCommand(["branch", "-a"], inDir: dir).output
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
        let finalRemote = remote.contains("fatal:") ? ws.remoteUrl : remote
        
        self.activeStatus = GitStatusInfo(
            isRepository: isRepo,
            currentBranch: finalBranch,
            modifiedFiles: modified,
            remoteUrl: finalRemote,
            availableBranches: fetchedBranches
        )
        self.remoteBranch = finalBranch
        self.selectedFilesToStage = Set(self.activeStatus.modifiedFiles)
        
        if let idx = workspaces.firstIndex(where: { $0.id == ws.id }) {
            workspaces[idx].selectedBranch = finalBranch
            if !finalRemote.isEmpty {
                workspaces[idx].remoteUrl = finalRemote
            }
            saveWorkspaces()
        }
        
        self.feedItems = [
            FeedCardItem(type: .info("Workspace opened\n\(dir) on \(finalBranch)")),
            FeedCardItem(type: .filesDetected(modified))
        ]
        self.currentStep = .stage
        self.completedSteps = []
    }
    
    // MARK: - Workflow Execution Steps
    public func executeStageFiles() {
        guard let ws = activeWorkspace else { return }
        let dir = ws.path
        let files = Array(selectedFilesToStage)
        
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
        
        _ = runGitCommand(["add", "."], inDir: dir)
        _ = runGitCommand(["commit", "-m", msg], inDir: dir)
        let count = selectedFilesToStage.isEmpty ? max(1, activeStatus.modifiedFiles.count) : selectedFilesToStage.count
        
        completedSteps.insert(.commit)
        feedItems.append(FeedCardItem(type: .commitSuccess(msg, count, activeStatus.currentBranch)))
        currentStep = .push
    }
    
    public func executePush() async {
        guard let ws = activeWorkspace else { return }
        let dir = ws.path
        let branch = remoteBranch.isEmpty ? activeStatus.currentBranch : remoteBranch
        
        isExecuting = true
        feedItems.append(FeedCardItem(type: .pushing(branch)))
        
        let targetRemote = activeStatus.remoteUrl.isEmpty ? ws.remoteUrl : activeStatus.remoteUrl
        if !targetRemote.isEmpty {
            _ = runGitCommand(["remote", "remove", "origin"], inDir: dir)
            _ = runGitCommand(["remote", "add", "origin", targetRemote], inDir: dir)
        }
        
        // Push attempt 1
        var pushResult = runGitCommand(["push", "-u", "origin", branch], inDir: dir)
        
        // If rejected due to remote initial commit, pull --rebase and retry push!
        if pushResult.isError || pushResult.output.contains("rejected") || pushResult.output.contains("fetch first") {
            _ = runGitCommand(["pull", "--rebase", "origin", branch], inDir: dir)
            pushResult = runGitCommand(["push", "-u", "origin", branch], inDir: dir)
        }
        
        isExecuting = false
        
        if pushResult.isError && (pushResult.output.contains("fatal:") || pushResult.output.contains("error:")) {
            feedItems.append(FeedCardItem(type: .pushError(pushResult.output)))
        } else {
            completedSteps.insert(.push)
            feedItems.append(FeedCardItem(type: .pushSuccess(branch)))
            currentStep = .openPR
        }
    }
    
    public func executeOpenPR() {
        completedSteps.insert(.openPR)
        
        let targetRemote = activeStatus.remoteUrl.isEmpty ? activeWorkspace?.remoteUrl ?? "" : activeStatus.remoteUrl
        var prUrlString = "https://github.com"
        
        if !targetRemote.isEmpty && targetRemote.contains("github.com") {
            let cleanRemote = targetRemote
                .replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
                .replacingOccurrences(of: ".git", with: "")
            prUrlString = "\(cleanRemote)/pull/new/\(remoteBranch)"
        }
        
        feedItems.append(FeedCardItem(type: .prSuccess(prUrlString)))
        feedItems.append(FeedCardItem(type: .completedAll))
        
        if let url = URL(string: prUrlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func clearTerminalLogs() {
        terminalLogs.removeAll()
    }
    
    // MARK: - Process Execution Helper
    @discardableResult
    private func runGitCommand(_ arguments: [String], inDir: String? = nil) -> (output: String, isError: Bool) {
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
        
        return (outputText, isErr)
    }
}
