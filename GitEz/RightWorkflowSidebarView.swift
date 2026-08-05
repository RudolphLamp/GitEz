import SwiftUI

struct RightWorkflowSidebarView: View {
    @EnvironmentObject var gitService: GitService
    
    var completedCount: Int {
        gitService.completedSteps.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // HEADER & STATUS COUNTER
            VStack(alignment: .leading, spacing: 6) {
                Text("GIT WORKFLOW")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.91, green: 0.29, blue: 0.25))
                    .tracking(1.2)
                
                Text("\(completedCount) of \(gitService.autoOpenPROnPush ? 5 : 4) steps done")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            
            // TOP GAUGE PROGRESS LINE
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.91, green: 0.29, blue: 0.25), Color(red: 0.65, green: 0.18, blue: 0.16)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(completedCount) / CGFloat(gitService.autoOpenPROnPush ? 5 : 4), height: 3)
                        .cornerRadius(2)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 20)
            
            // VERTICAL TIMELINE NODES
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(WorkflowStep.allCases) { step in
                        let isDone = gitService.completedSteps.contains(step)
                        let isCurrent = gitService.currentStep == step && !isDone
                        
                        HStack(alignment: .top, spacing: 14) {
                            // Left Icon Timeline Circle
                            ZStack {
                                Circle()
                                    .fill(
                                        isDone ? Color(red: 0.85, green: 0.25, blue: 0.22) :
                                            (isCurrent ? Color(red: 0.55, green: 0.15, blue: 0.14) : Color.white.opacity(0.06))
                                    )
                                    .frame(width: 28, height: 28)
                                    .shadow(color: isCurrent ? Color(red: 0.91, green: 0.29, blue: 0.25).opacity(0.4) : Color.clear, radius: 6, x: 0, y: 2)
                                
                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: step.iconName)
                                        .font(.system(size: 12))
                                        .foregroundColor(isCurrent ? .white : Color.white.opacity(0.4))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(step.title)
                                        .font(.system(size: 13, weight: (isDone || isCurrent) ? .bold : .semibold, design: .rounded))
                                        .foregroundColor((isDone || isCurrent) ? .white : Color.white.opacity(0.5))
                                    
                                    if isDone {
                                        Text("DONE")
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(red: 0.91, green: 0.29, blue: 0.25))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(red: 0.91, green: 0.29, blue: 0.25).opacity(0.18))
                                            .cornerRadius(6)
                                    } else if isCurrent {
                                        Text("NOW")
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.45))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(red: 0.91, green: 0.29, blue: 0.25).opacity(0.3))
                                            .cornerRadius(6)
                                    }
                                }
                                
                                Text(step.subtitle)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.4))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        
                        if step != .openPR {
                            Rectangle()
                                .fill(isDone ? Color(red: 0.85, green: 0.25, blue: 0.22) : Color.white.opacity(0.08))
                                .frame(width: 2, height: 16)
                                .padding(.leading, 33)
                        }
                    }
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .frame(width: 260)
        .background(
            ZStack {
                VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
                Color(red: 0.08, green: 0.05, blue: 0.06).opacity(0.92)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    RightWorkflowSidebarView()
        .environmentObject(GitService())
        .frame(width: 260, height: 600)
}
