import SwiftUI
import AppKit

struct RepoInsightsView: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t
    
    @State private var copiedUrlNotice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [t.accent, t.accentSecondary],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Repository Insights")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(t.textPrimary)
                        Text(gitService.activeWorkspace?.name ?? "No Workspace Selected")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(t.textSecondary)
                    }

                    Spacer()

                    // Back to workspace
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            gitService.currentSection = .workspace
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left").font(.system(size: 11))
                            Text("Back to Pipeline").font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(t.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                // Overview Metric Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    metricCard(title: "Active Branch", value: gitService.activeStatus.currentBranch.isEmpty ? "main" : gitService.activeStatus.currentBranch, icon: "arrow.triangle.branch", color: t.accent)
                    metricCard(title: "Modified Files", value: "\(gitService.activeStatus.modifiedFiles.count)", icon: "doc.badge.gearshape", color: Color.orange)
                    metricCard(title: "Total Commits", value: "\(gitService.commitHistory.count)", icon: "clock.arrow.circlepath", color: Color.blue)
                    metricCard(title: "Available Branches", value: "\(gitService.activeStatus.availableBranches.count)", icon: "git.branch", color: Color.green)
                }

                // Remote Repository Connection Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(t.accent)
                        Text("Remote Origin Target")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(t.textPrimary)
                        Spacer()

                        if copiedUrlNotice {
                            Text("Copied URL! ✓")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(t.accent)
                        }

                        Button(action: copyRemoteUrl) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc").font(.system(size: 10))
                                Text("Copy Remote URL").font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(t.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(gitService.activeStatus.remoteUrl.isEmpty ? (gitService.activeWorkspace?.remoteUrl ?? "No remote URL configured") : gitService.activeStatus.remoteUrl)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(t.textPrimary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(18)
                .background(t.surface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.border, lineWidth: 1))

                // Recent Activity Distribution Chart
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(t.accent)
                        Text("Commit Activity Breakdown")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(t.textPrimary)
                        Spacer()
                    }

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<12, id: \.self) { idx in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(
                                        colors: [t.accent.opacity(0.8), t.accentSecondary],
                                        startPoint: .top, endPoint: .bottom))
                                    .frame(height: CGFloat([35, 60, 25, 90, 45, 80, 110, 50, 75, 40, 95, 65][idx]))
                                Text("W\(idx + 1)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(t.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 140)
                    .padding(.top, 8)
                }
                .padding(18)
                .background(t.surface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.border, lineWidth: 1))
            }
            .padding(32)
        }
        .background(t.background)
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(t.textPrimary)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(t.textSecondary)
            }
        }
        .padding(14)
        .background(t.surface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 1))
    }

    private func copyRemoteUrl() {
        let urlStr = gitService.activeStatus.remoteUrl.isEmpty ? (gitService.activeWorkspace?.remoteUrl ?? "") : gitService.activeStatus.remoteUrl
        guard !urlStr.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(urlStr, forType: .string)
        withAnimation { copiedUrlNotice = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { copiedUrlNotice = false }
        }
    }
}
