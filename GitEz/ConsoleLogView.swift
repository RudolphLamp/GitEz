import SwiftUI

struct ConsoleLogView: View {
    @EnvironmentObject var gitService: GitService
    
    var body: some View {
        VStack {
            Text("Console Logs")
                .font(.headline)
        }
    }
}
