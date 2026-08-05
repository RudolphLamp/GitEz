import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var gitService: GitService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // BRANDING HEADER LOGO WITH SOFT GLOW
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.8, blue: 0.4), Color(red: 0.08, green: 0.55, blue: 0.28)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.4), radius: 8, x: 0, y: 3)
                    
                    Image(systemName: "circle.hexagonpath")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 1) {
                    Text("Git")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                    Text("Ez")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 20)
            
            // WORKSPACES SECTION LABEL
            HStack {
                Text("WORKSPACES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
                    .tracking(1.2)
                Spacer()
                Text("\(gitService.workspaces.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // WORKSPACE LIST ITEMS SCROLL
            ScrollView {
                VStack(spacing: 6) {
                    if gitService.workspaces.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 24))
                                .foregroundColor(Color.white.opacity(0.3))
                            Text("No Workspaces")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                            Text("Click + Add workspace below to get started")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.35))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 16)
                    } else {
                        ForEach(gitService.workspaces) { ws in
                            let isSelected = gitService.selectedWorkspaceID == ws.id
                            
                            Button(action: {
                                gitService.selectedWorkspaceID = ws.id
                                gitService.refreshActiveStatus()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(
                                                isSelected ?
                                                LinearGradient(colors: [Color(red: 0.15, green: 0.75, blue: 0.35), Color(red: 0.1, green: 0.55, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                                LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                            .frame(width: 34, height: 34)
                                        
                                        Text(String(ws.name.prefix(1)).uppercased())
                                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(ws.name)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(isSelected ? .white : Color.white.opacity(0.75))
                                        
                                        Text(ws.selectedBranch.isEmpty ? "main" : ws.selectedBranch)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(isSelected ? Color(red: 0.45, green: 0.9, blue: 0.6) : Color.white.opacity(0.4))
                                    }
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Circle()
                                            .fill(Color(red: 0.35, green: 0.85, blue: 0.5))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    isSelected ? Color.white.opacity(0.08) : Color.clear
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? Color(red: 0.3, green: 0.8, blue: 0.4).opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Remove Workspace", role: .destructive) {
                                    gitService.removeWorkspace(id: ws.id)
                                }
                            }
                        }
                    }
                    
                    // ADD WORKSPACE GLASS BUTTON
                    Button(action: {
                        gitService.showAddWorkspaceModal = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("Add workspace")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Spacer()
                        }
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.1, green: 0.3, blue: 0.18).opacity(0.3))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 12)
            }
            
            // QUICK TOOLBAR ITEMS
            VStack(spacing: 4) {
                // COMMIT HISTORY DRAWER TOGGLE BUTTON
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        gitService.showHistoryDrawer.toggle()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(gitService.showHistoryDrawer ? Color(red: 0.35, green: 0.85, blue: 0.5) : Color.white.opacity(0.6))
                        
                        Text("GitHub Commit History")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(gitService.showHistoryDrawer ? .white : Color.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(gitService.commitHistory.count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(gitService.showHistoryDrawer ? Color(red: 0.1, green: 0.3, blue: 0.18).opacity(0.4) : Color.white.opacity(0.04))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // USER ACCOUNT FOOTER
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Text(String(gitService.gitUser.username.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(gitService.gitUser.username.isEmpty ? "username" : gitService.gitUser.username)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("Settings")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                
                Spacer()
                
                Button(action: {
                    gitService.showSettingsModal = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(6)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
        }
        .frame(width: 250)
        .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
    }
}

#Preview {
    SidebarView()
        .environmentObject(GitService())
}
