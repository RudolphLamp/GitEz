import SwiftUI

struct CommitHistoryModalView: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { gitService.showHistoryModal = false }

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 15))
                        .foregroundColor(t.accent)
                    Text("Commit History")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(t.textPrimary)
                    Spacer()
                    if !gitService.commitHistory.isEmpty {
                        Text("\(gitService.commitHistory.count) commits")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(t.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(t.accentMuted)
                            .cornerRadius(6)
                    }
                    Button(action: { gitService.showHistoryModal = false }) {
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
                .padding(.bottom, 6)

                Text("Click any commit to view its diff on GitHub.")
                    .font(.system(size: 12))
                    .foregroundColor(t.textTertiary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                Rectangle().fill(t.divider).frame(height: 1)

                // Commit list
                if gitService.commitHistory.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.system(size: 26))
                            .foregroundColor(t.textTertiary)
                        Text("No commits yet in this workspace")
                            .font(.system(size: 13))
                            .foregroundColor(t.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(gitService.commitHistory) { item in
                                CommitRow(item: item)
                                Rectangle().fill(t.divider).frame(height: 1).padding(.horizontal, 24)
                            }
                        }
                    }
                    .frame(height: 340)
                }

                Rectangle().fill(t.divider).frame(height: 1)

                // Footer
                HStack {
                    Spacer()
                    Button(action: { gitService.showHistoryModal = false }) {
                        Text("Close")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(t.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 9)
                            .background(t.surfaceElevated)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            .frame(width: 540)
            .background(t.surface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.border, lineWidth: 1))
        }
    }
}

// MARK: - Commit Row
private struct CommitRow: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t
    let item: CommitLogItem
    @State private var hovered = false

    var body: some View {
        Button(action: { gitService.openCommitOnGitHub(item.hash) }) {
            HStack(alignment: .top, spacing: 14) {
                // Short hash badge
                Text(item.shortHash)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(t.accentMuted)
                    .cornerRadius(5)
                    .fixedSize()

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(t.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(item.author)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(t.textSecondary)
                        Text("·")
                            .foregroundColor(t.textTertiary)
                        Text(item.dateString)
                            .font(.system(size: 11))
                            .foregroundColor(t.textTertiary)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("GitHub")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(hovered ? t.accent : t.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(hovered ? t.accentMuted : t.surfaceElevated)
                .cornerRadius(6)
                .animation(.easeInOut(duration: 0.12), value: hovered)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(hovered ? t.accentMuted.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

#Preview {
    CommitHistoryModalView()
        .environmentObject(GitService())
        .environment(\.theme, ThemeColors.make(.dark))
}
