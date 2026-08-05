import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var gitService: GitService
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            Color(red: 0.06, green: 0.08, blue: 0.1)
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // TOP LOGO HEADER (GitEz BRANDING)
                HStack(spacing: 8) {
                    Image(systemName: "circle.hexagonpath")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    
                    HStack(spacing: 1) {
                        Text("Git")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        Text("Ez")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 20)
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // WORKSPACES HEADER
                Text("WORKSPACES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.4))
                    .tracking(1.2)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                // WORKSPACES LIST
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(gitService.workspaces) { ws in
                            let isSelected = gitService.selectedWorkspaceID == ws.id
                            let initial = String(ws.name.prefix(1)).capitalized
                            let branch = isSelected ? gitService.activeStatus.currentBranch : (ws.selectedBranch.isEmpty ? "main" : ws.selectedBranch)
                            
                            Button(action: {
                                gitService.selectedWorkspaceID = ws.id
                                gitService.refreshActiveStatus()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(isSelected ? Color(red: 0.1, green: 0.5, blue: 0.25) : Color.white.opacity(0.08))
                                            .frame(width: 32, height: 32)
                                        
                                        Text(initial)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(isSelected ? Color(red: 0.4, green: 0.95, blue: 0.6) : Color.white.opacity(0.6))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(ws.name)
                                            .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                                            .foregroundColor(isSelected ? .white : Color.white.opacity(0.8))
                                        
                                        Text(branch)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(isSelected ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.4))
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(
                                    isSelected ? Color(red: 0.1, green: 0.35, blue: 0.2).opacity(0.6) : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.35) : Color.clear, lineWidth: 1.2)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    gitService.removeWorkspace(id: ws.id)
                                } label: {
                                    Label("Remove Workspace", systemImage: "trash")
                                }
                            }
                        }
                        
                        // ADD WORKSPACE BUTTON (TRIGGERS MODAL)
                        Button(action: { gitService.showAddWorkspaceModal = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Add workspace")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(Color.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.white.opacity(0.02))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // BOTTOM PROFILE ROW (MODAL TRIGGER)
                Button(action: { gitService.showSettingsModal = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Text(String((gitService.gitUser.username.isEmpty ? "R" : gitService.gitUser.username).prefix(1)).capitalized)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(gitService.gitUser.username.isEmpty ? "rudolph" : gitService.gitUser.username)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Settings")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(16)
            }
        }
        .frame(width: 250)
    }
}

#Preview {
    SidebarView()
        .environmentObject(GitService())
        .frame(width: 250, height: 600)
}
