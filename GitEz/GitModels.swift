import Foundation

public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    public var id: String { self.rawValue }
}

public struct Workspace: Identifiable, Hashable, Codable {
    public var id: UUID
    public var name: String
    public var path: String
    public var remoteUrl: String
    public var selectedBranch: String
    
    public init(id: UUID = UUID(), name: String, path: String, remoteUrl: String = "", selectedBranch: String = "main") {
        self.id = id
        self.name = name
        self.path = path
        self.remoteUrl = remoteUrl
        self.selectedBranch = selectedBranch
    }
}

public struct GitBranch: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let isRemote: Bool
    public let isCurrent: Bool
}

public struct GitUser: Equatable {
    public var username: String
    public var email: String
    public var token: String
    
    public var isValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }
}

public enum WorkflowStep: Int, CaseIterable, Identifiable {
    case stage = 1
    case writeCommit = 2
    case commit = 3
    case push = 4
    case openPR = 5

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .stage: return "Stage files"
        case .writeCommit: return "Write commit"
        case .commit: return "Commit"
        case .push: return "Push to remote"
        case .openPR: return "Open pull request"
        }
    }

    public var subtitle: String {
        switch self {
        case .stage: return "Select changed files to include in your commit"
        case .writeCommit: return "Describe what this commit does"
        case .commit: return "Save your staged changes locally"
        case .push: return "Upload commits to GitHub"
        case .openPR: return "Start a review for your changes"
        }
    }

    var iconName: String {
        switch self {
        case .stage: return "square.stack.fill"
        case .writeCommit: return "square.and.pencil"
        case .commit: return "briefcase.fill"
        case .push: return "cloud.upload.fill"
        case .openPR: return "arrow.triangle.pull"
        }
    }
}

public struct TerminalLogEntry: Identifiable {
    public let id = UUID()
    public let timestamp = Date()
    public let command: String
    public let output: String
    public let isError: Bool
}

public enum FeedItemType {
    case info(String)
    case filesDetected([String])
    case stepActive(WorkflowStep)
    case stagedSuccess(Int, [String])
    case commitSuccess(String, Int, String)
    case pushing(String)
    case pushSuccess(String)
    case pushError(String)
    case prSuccess(String)
    case completedAll
}

public struct FeedCardItem: Identifiable {
    public let id = UUID()
    public let timestamp = Date()
    public let type: FeedItemType
}

public struct GitStatusInfo {
    public var isRepository: Bool = false
    public var currentBranch: String = "main"
    public var modifiedFiles: [String] = []
    public var remoteUrl: String = ""
    public var availableBranches: [GitBranch] = []
}
