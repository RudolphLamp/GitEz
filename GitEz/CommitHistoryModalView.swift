import SwiftUI

struct CommitHistoryModalView: View {
    @EnvironmentObject var gitService: GitService
    
    var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    gitService.showHistoryModal = false
                }
            
            // Glass Modal Container
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        
                        Text("GitHub Commit & Push History")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("\(gitService.commitHistory.count) Commits")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                        .cornerRadius(6)
                    
                    Button(action: { gitService.showHistoryModal = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Text("Click any commit to open its exact view and diff on GitHub.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Commit Rows List
                if gitService.commitHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundColor(Color.white.opacity(0.3))
                        Text("No commits recorded yet in this workspace")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(gitService.commitHistory) { item in
                                Button(action: {
                                    gitService.openCommitOnGitHub(item.hash)
                                }) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text(item.shortHash)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                                            .cornerRadius(6)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.message)
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.leading)
                                            
                                            HStack(spacing: 6) {
                                                Text(item.author)
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(Color.white.opacity(0.5))
                                                
                                                Text("·")
                                                    .foregroundColor(Color.white.opacity(0.3))
                                                
                                                Text(item.dateString)
                                                    .font(.system(size: 11, design: .rounded))
                                                    .foregroundColor(Color.white.opacity(0.4))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Text("View on GitHub")
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            Image(systemName: "arrow.up.forward")
                                                .font(.system(size: 9, weight: .bold))
                                        }
                                        .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.06))
                                        .cornerRadius(6)
                                    }
                                    .padding(12)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 320)
                }
                
                Button(action: { gitService.showHistoryModal = false }) {
                    Text("Close")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(width: 520)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    Color(red: 0.08, green: 0.1, blue: 0.13).opacity(0.92)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 12)
        }
    }
}

#Preview {
    CommitHistoryModalView()
        .environmentObject(GitService())
}
