import SwiftUI

struct ContentView: View {
    @StateObject private var gitService = GitService()
    @AppStorage("appTheme")     private var selectedTheme: AppTheme = .dark
    @AppStorage("accentPreset") private var accentRaw: String = AccentPreset.gitez.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var resolvedTheme: AppTheme {
        selectedTheme == .system ? (colorScheme == .dark ? .dark : .light) : selectedTheme
    }

    private var accent: AccentPreset {
        AccentPreset(rawValue: accentRaw) ?? .gitez
    }

    private var t: ThemeColors {
        ThemeColors.make(resolvedTheme, accent)
    }

    var body: some View {
        ZStack {
            t.background.ignoresSafeArea()

            if !gitService.gitUser.isValid {
                LoginView()
            } else {
                HStack(spacing: 0) {
                    // Left sidebar
                    SidebarView()

                    // Thin 1px separator
                    Rectangle()
                        .fill(t.divider)
                        .frame(width: 1)

                    // Main content — workspace or settings
                    Group {
                        if gitService.currentSection == .settings {
                            SettingsPageView()
                        } else {
                            MainFeedView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .animation(.easeInOut(duration: 0.18), value: gitService.currentSection)
            }
        }
        .environmentObject(gitService)
        .environment(\.theme, t)
        .frame(minWidth: 1020, minHeight: 660)
        // ── Modal overlays ──
        .overlay {
            if gitService.showAddWorkspaceModal {
                AddWorkspaceModalView()
                    .environmentObject(gitService)
                    .environment(\.theme, t)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .center)))
            }
        }
        .overlay {
            if gitService.showHistoryModal {
                CommitHistoryModalView()
                    .environmentObject(gitService)
                    .environment(\.theme, t)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .center)))
            }
        }
        .animation(.easeInOut(duration: 0.14), value: gitService.showAddWorkspaceModal)
        .animation(.easeInOut(duration: 0.14), value: gitService.showHistoryModal)
    }
}

#Preview {
    ContentView().frame(width: 1100, height: 720)
}
