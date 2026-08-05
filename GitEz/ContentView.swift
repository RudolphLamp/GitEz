import SwiftUI

struct ContentView: View {
    @StateObject private var gitService = GitService()
    @AppStorage("appTheme") private var selectedTheme: AppTheme = .dark
    
    var body: some View {
        ZStack {
            // Dark Liquid Glass Window Background
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            Color(red: 0.05, green: 0.07, blue: 0.09)
                .opacity(0.92)
                .ignoresSafeArea()
            
            if !gitService.gitUser.isValid {
                LoginView()
            } else {
                HStack(spacing: 0) {
                    // LEFT WORKSPACE SIDEBAR
                    SidebarView()
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    // MIDDLE MAIN INTERACTIVE FEED
                    MainFeedView()
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    // RIGHT WORKFLOW STATUS PANEL
                    RightWorkflowSidebarView()
                }
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
        }
        .environmentObject(gitService)
        .frame(minWidth: 1080, minHeight: 720)
    }
}

#Preview {
    ContentView()
        .frame(width: 1100, height: 750)
}
