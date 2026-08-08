import SwiftUI

// MARK: - Sidebar
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

            // ── App title header ──
            HStack(spacing: 8) {
                Text("ZGit")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(t.textPrimary)
                    .tracking(-0.4)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 16)

            // ── Search bar ──
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
                    Text("/")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(t.textTertiary)
                        .frame(width: 20, height: 18)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal, 10)
            .padding(.bottom, 18)

            // ── Projects header ──
            HStack {
                Text("PROJECTS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(t.textTertiary)
                    .tracking(1.0)
                Spacer()
                Button(action: { gitService.showAddWorkspaceModal = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(t.textSecondary)
                        .frame(width: 22, height: 20)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)

            // ── Workspace list ──
            ScrollView(showsIndicators: false) {
                VStack(spacing: 1) {
                    if filteredWorkspaces.isEmpty {
                        VStack(spacing: 10) {
                            Text(searchQuery.isEmpty ? "No projects yet" : "No matches")
                                .font(.system(size: 12))
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
                        .padding(.vertical, 28)
                    } else {
                        ForEach(filteredWorkspaces) { ws in
                            WorkspaceRow(workspace: ws)
                        }
                    }
                }
                .padding(.horizontal, 6)
            }

            Spacer(minLength: 0)

            Rectangle().fill(t.divider).frame(height: 1)

            // ── Bottom navigation ──
            VStack(spacing: 2) {
                NavRow(icon: "clock.arrow.circlepath",
                       label: "History",
                       badge: gitService.commitHistory.isEmpty ? nil : "\(gitService.commitHistory.count)") {
                    gitService.showHistoryModal = true
                }
                NavRow(icon: "gearshape",
                       label: "Settings",
                       isActive: gitService.currentSection == .settings) {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        gitService.currentSection = gitService.currentSection == .settings ? .workspace : .settings
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)

            Rectangle().fill(t.divider).frame(height: 1)

            // ── User footer ──
            HStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(t.accent)
                        .frame(width: 24, height: 24)
                    Text(String(gitService.gitUser.username.prefix(1)).uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                Text(gitService.gitUser.username.isEmpty ? "Set up account" : "@\(gitService.gitUser.username)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(t.textSecondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 232)
        .background(t.sidebar)
    }
}

// MARK: - Workspace Row
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
                // Accent bar
                RoundedRectangle(cornerRadius: 1)
                    .fill(isSelected ? t.accent : Color.clear)
                    .frame(width: 2)
                    .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(workspace.name)
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .foregroundColor(isSelected ? t.textPrimary : t.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.branch").font(.system(size: 8))
                        Text(workspace.selectedBranch.isEmpty ? "main" : workspace.selectedBranch)
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(isSelected ? t.accent.opacity(0.8) : t.textTertiary)
                }
                .padding(.leading, 10)
                .padding(.vertical, 7)

                Spacer()

                if changeCount > 0 {
                    Text("\(changeCount)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(t.accent)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(t.accentMuted)
                        .cornerRadius(4)
                        .padding(.trailing, 10)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected
                          ? Color.white.opacity(0.07)
                          : (hovered ? Color.white.opacity(0.04) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: hovered)
        .contextMenu {
            Button("Remove Project", role: .destructive) {
                gitService.removeWorkspace(id: workspace.id)
            }
        }
    }
}

// MARK: - Nav Row
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
                    .font(.system(size: 13))
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
