import SwiftUI
import AppKit

// MARK: - Sidebar View
struct SidebarView: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t

    @State private var searchQuery = ""

    var filteredWorkspaces: [Workspace] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return gitService.workspaces
        } else {
            return gitService.workspaces.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.path.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── 1. Logo / Window Header ──
            HStack(spacing: 9) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .cornerRadius(6)
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text("ZGit")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(t.textPrimary)
                        Text("v2.5")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(t.accent)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(t.accentMuted)
                            .cornerRadius(4)
                    }
                    Text("macOS 27 Liquid Glass")
                        .font(.system(size: 10))
                        .foregroundColor(t.textTertiary)
                }

                Spacer()

                // Refresh Status Button
                Button(action: { gitService.refreshActiveStatus() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(t.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Refresh Git status (⌘R)")
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // ── 2. Live Search Box ──
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(t.textTertiary)
                TextField("Search projects…", text: $searchQuery)
                    .font(.system(size: 12))
                    .textFieldStyle(.plain)
                    .foregroundColor(t.textPrimary)
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(t.textTertiary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("⌘K")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(t.textTertiary)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 1))
            .padding(.horizontal, 12)
            .padding(.bottom, 14)

            // ── 3. Active Repository Summary Card ──
            if let activeWs = gitService.activeWorkspace {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle().fill(gitService.activeStatus.modifiedFiles.isEmpty ? Color.green : t.accent)
                            .frame(width: 6, height: 6)
                        Text(activeWs.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(t.textPrimary)
                            .lineLimit(1)
                        Spacer()
                    }

                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.branch").font(.system(size: 8))
                            Text(gitService.activeStatus.currentBranch.isEmpty ? "main" : gitService.activeStatus.currentBranch)
                                .font(.system(size: 10, design: .monospaced))
                        }
                        .foregroundColor(t.accent)

                        Spacer()

                        Text("\(gitService.activeStatus.modifiedFiles.count) changed")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(t.textSecondary)
                    }

                    // IDE Quick Launcher Row
                    HStack(spacing: 6) {
                        Button(action: { gitService.openInIDE(.vscode) }) {
                            HStack(spacing: 3) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right").font(.system(size: 8))
                                Text("VS Code").font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(t.textSecondary)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)

                        Button(action: { gitService.openInIDE(.finder) }) {
                            HStack(spacing: 3) {
                                Image(systemName: "folder").font(.system(size: 8))
                                Text("Finder").font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(t.textSecondary)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.top, 2)
                }
                .padding(10)
                .background(t.surface)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 1))
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }

            // ── 4. Projects Section Header ──
            HStack {
                Text("WORKSPACES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(t.textTertiary)
                    .tracking(1.0)
                Spacer()
                Button(action: { gitService.showAddWorkspaceModal = true }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Add")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(t.accentMuted)
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)

            // ── 5. Workspace List ──
            ScrollView(showsIndicators: false) {
                VStack(spacing: 2) {
                    if filteredWorkspaces.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 22))
                                .foregroundColor(t.textTertiary)
                            Text(searchQuery.isEmpty ? "No projects added" : "No matching projects")
                                .font(.system(size: 11))
                                .foregroundColor(t.textTertiary)
                            if searchQuery.isEmpty {
                                Button(action: { gitService.showAddWorkspaceModal = true }) {
                                    Text("Add project")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(t.accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(filteredWorkspaces) { ws in
                            WorkspaceRow(workspace: ws)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)

            Rectangle().fill(t.divider).frame(height: 1)

            // ── 6. Navigation Options ──
            VStack(spacing: 2) {
                NavRow(icon: "sidebar.left",
                       label: "Pipeline Feed",
                       isActive: gitService.currentSection == .workspace) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        gitService.currentSection = .workspace
                    }
                }
                NavRow(icon: "chart.bar",
                       label: "Repository Insights",
                       isActive: gitService.currentSection == .insights) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        gitService.currentSection = .insights
                    }
                }
                NavRow(icon: "clock.arrow.circlepath",
                       label: "Commit History",
                       badge: gitService.commitHistory.isEmpty ? nil : "\(gitService.commitHistory.count)") {
                    gitService.showHistoryModal = true
                }
                NavRow(icon: "terminal",
                       label: "Debug Console",
                       isActive: gitService.showTerminalConsole) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        gitService.showTerminalConsole.toggle()
                    }
                }
                NavRow(icon: "gearshape",
                       label: "Settings",
                       isActive: gitService.currentSection == .settings) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        gitService.currentSection = gitService.currentSection == .settings ? .workspace : .settings
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)

            Rectangle().fill(t.divider).frame(height: 1)

            // ── 7. User Profile Card ──
            HStack(spacing: 9) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [t.accent, t.accentSecondary],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 26, height: 26)
                    Text(String(gitService.gitUser.username.prefix(1)).uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(t.sidebar, lineWidth: 1.5))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(gitService.gitUser.username.isEmpty ? "Set up account" : "@\(gitService.gitUser.username)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(t.textPrimary)
                        .lineLimit(1)
                    Text(gitService.gitUser.token.isEmpty ? "No PAT Token" : "Token Active ✓")
                        .font(.system(size: 9))
                        .foregroundColor(gitService.gitUser.token.isEmpty ? t.textTertiary : Color.green)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 232)
        .background(t.sidebar)
    }
}

// MARK: - Workspace Row Component
private struct WorkspaceRow: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t
    let workspace: Workspace
    @State private var hovered = false

    var isSelected: Bool { gitService.selectedWorkspaceID == workspace.id && gitService.currentSection == .workspace }
    var changeCount: Int { isSelected ? gitService.activeStatus.modifiedFiles.count : 0 }

    var body: some View {
        Button(action: {
            gitService.selectedWorkspaceID = workspace.id
            gitService.currentSection = .workspace
            gitService.refreshActiveStatus()
        }) {
            HStack(spacing: 0) {
                // Left Accent Line
                RoundedRectangle(cornerRadius: 1)
                    .fill(isSelected ? t.accent : Color.clear)
                    .frame(width: 2)
                    .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(workspace.name)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? t.textPrimary : t.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch").font(.system(size: 8))
                        Text(workspace.selectedBranch.isEmpty ? "main" : workspace.selectedBranch)
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(isSelected ? t.accent : t.textTertiary)
                }
                .padding(.leading, 10)
                .padding(.vertical, 7)

                Spacer()

                if changeCount > 0 {
                    Text("\(changeCount)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(t.accent)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(t.accentMuted)
                        .cornerRadius(4)
                        .padding(.trailing, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected
                          ? Color.white.opacity(0.08)
                          : (hovered ? Color.white.opacity(0.04) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: hovered)
        .contextMenu {
            Button("Open in VS Code") { gitService.openInIDE(.vscode, path: workspace.path) }
            Button("Open in Finder") { gitService.openInIDE(.finder, path: workspace.path) }
            Divider()
            Button("Remove Workspace", role: .destructive) {
                gitService.removeWorkspace(id: workspace.id)
            }
        }
    }
}

// MARK: - Nav Row Component
private struct NavRow: View {
    @Environment(\.theme) var t
    let icon: String
    let label: String
    var badge: String? = nil
    var isActive: Bool = false
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? t.accent : (hovered ? t.textPrimary : t.textSecondary))
                    .frame(width: 14)
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? t.accent : (hovered ? t.textPrimary : t.textSecondary))
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(t.accent)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(t.accentMuted)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive
                          ? t.accentMuted
                          : (hovered ? Color.white.opacity(0.04) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: hovered)
    }
}
