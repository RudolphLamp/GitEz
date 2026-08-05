import SwiftUI

struct ContentView: View {
    @StateObject private var gitService = GitService()
    @AppStorage("appTheme") private var selectedTheme: AppTheme = .dark
    
    var body: some View {
        ZStack {
            // Dark Liquid Glass Window Background
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            Color(red: 0.05, green: 0.04, blue: 0.05)
                .opacity(0.92)
                .ignoresSafeArea()
            
            if !gitService.gitUser.isValid {
                LoginView()
            } else {
                HStack(spacing: 12) {
                    // LEFT WORKSPACE SIDEBAR (FLOATING GLASS CARD)
                    SidebarView()
                    
                    // MIDDLE MAIN INTERACTIVE FEED (FLOATING GLASS CARD)
                    MainFeedView()
                        .background(
                            ZStack {
                                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                                Color(red: 0.07, green: 0.05, blue: 0.06).opacity(0.85)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
                    
                    // RIGHT WORKFLOW STATUS PANEL (FLOATING GLASS CARD)
                    RightWorkflowSidebarView()
                }
                .padding(12)
            }
            
            // SETTINGS MODAL OVERLAY
            if gitService.showSettingsModal {
                SettingsModalView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // ADD WORKSPACE MODAL OVERLAY
            if gitService.showAddWorkspaceModal {
                AddWorkspaceModalView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // COMMIT HISTORY POP-UP MODAL OVERLAY
            if gitService.showHistoryModal {
                CommitHistoryModalView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .environmentObject(gitService)
        .frame(minWidth: 1100, minHeight: 740)
    }
}

#Preview {
    ContentView()
        .frame(width: 1120, height: 760)
}
