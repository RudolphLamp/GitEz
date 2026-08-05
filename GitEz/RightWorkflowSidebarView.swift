import SwiftUI

struct RightWorkflowSidebarView: View {
    @EnvironmentObject var gitService: GitService
    
    var completedCount: Int {
        gitService.completedSteps.count
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            Color(red: 0.07, green: 0.09, blue: 0.11)
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 18) {
                // HEADER & STATUS COUNTER
                VStack(alignment: .leading, spacing: 6) {
                    Text("GIT WORKFLOW")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                        .tracking(1.2)
                    
                    Text("\(completedCount) of 5 steps done")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                
                // TOP GAUGE PROGRESS LINE
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 3)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.4, green: 0.7, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(completedCount) / 5.0, height: 3)
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
                                            isDone ? Color(red: 0.15, green: 0.75, blue: 0.35) :
                                                (isCurrent ? Color(red: 0.15, green: 0.45, blue: 0.75) : Color.white.opacity(0.06))
                                        )
                                        .frame(width: 28, height: 28)
                                    
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
                                                .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.5))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(red: 0.15, green: 0.75, blue: 0.35).opacity(0.2))
                                                .cornerRadius(4)
                                        } else if isCurrent {
                                            Text("NOW")
                                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                                .foregroundColor(Color.cyan)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.cyan.opacity(0.2))
                                                .cornerRadius(4)
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
                                    .fill(isDone ? Color(red: 0.2, green: 0.7, blue: 0.35) : Color.white.opacity(0.08))
                                    .frame(width: 2, height: 16)
                                    .padding(.leading, 33)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
            }
        }
        .frame(width: 260)
    }
}

#Preview {
    RightWorkflowSidebarView()
        .environmentObject(GitService())
        .frame(width: 260, height: 600)
}
