import SwiftUI
import AppKit

struct ConsoleLogView: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t

    @State private var copiedNotice = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 13))
                        .foregroundColor(t.accent)
                    Text("Debug Console Logs")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(t.textPrimary)
                    Text("(\(gitService.terminalLogs.count) entries)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(t.textTertiary)
                }

                Spacer()

                if copiedNotice {
                    Text("Copied to Clipboard! ✓")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(t.accent)
                        .transition(.opacity)
                }

                Button(action: copyDebugLogs) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc").font(.system(size: 10))
                        Text("Copy Debug Logs").font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(t.accent)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { gitService.clearTerminalLogs() }) {
                    Text("Clear")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(t.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { gitService.showTerminalConsole = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(t.textTertiary)
                        .padding(5)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(t.surface)

            Rectangle().fill(t.divider).frame(height: 1)

            // Log entries scroll view
            if gitService.terminalLogs.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "terminal")
                        .font(.system(size: 26))
                        .foregroundColor(t.textTertiary)
                    Text("No debug log entries recorded yet.")
                        .font(.system(size: 12))
                        .foregroundColor(t.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(t.terminalBg)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(gitService.terminalLogs) { entry in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(entry.timestamp, style: .time)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(t.textTertiary)
                                        Text("$ " + entry.command)
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundColor(entry.isError ? t.codeRemovedFg : t.accent)
                                        Spacer()
                                    }
                                    if !entry.output.isEmpty {
                                        Text(entry.output)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(entry.isError ? t.codeRemovedFg.opacity(0.9) : t.textSecondary)
                                            .padding(6)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(5)
                                    }
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(6)
                                .id(entry.id)
                            }
                        }
                        .padding(10)
                    }
                    .background(t.terminalBg)
                }
            }
        }
        .frame(height: 220)
        .background(t.surface)
    }

    private func copyDebugLogs() {
        let activeWsPath = gitService.activeWorkspace?.path ?? "None"
        let activeBranch = gitService.activeStatus.currentBranch
        var export = "=== ZGit Debug Log Dump ===\n"
        export += "Workspace: \(activeWsPath)\n"
        export += "Current Branch: \(activeBranch)\n"
        export += "Current Step: \(gitService.currentStep.title)\n"
        export += "Modified Files (\(gitService.activeStatus.modifiedFiles.count)): \(gitService.activeStatus.modifiedFiles.joined(separator: ", "))\n"
        export += "--------------------------------------\n"
        for log in gitService.terminalLogs {
            export += "[\(log.timestamp)] $ \(log.command)\n"
            if !log.output.isEmpty {
                export += "\(log.output)\n"
            }
            export += "\n"
        }
        
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(export, forType: .string)

        withAnimation { copiedNotice = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { copiedNotice = false }
        }
    }
}

#Preview {
    ConsoleLogView()
        .environmentObject(GitService())
        .environment(\.theme, ThemeColors.make(.dark))
}
