import SwiftUI
import AppKit

@main
struct GitEzApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor())
                .onAppear {
                    setDockIcon()
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
    
    private func setDockIcon() {
        let iconPaths = [
            "/Users/zaza/Documents/GitEz/ICONS/Icon-iOS-Dark-1024@1x.png",
            "/Users/zaza/Documents/icon/Ezgit/Icon Exports/Icon-iOS-Dark-1024@1x.png"
        ]
        
        for path in iconPaths {
            if FileManager.default.fileExists(atPath: path),
               let image = NSImage(contentsOfFile: path) {
                image.size = NSSize(width: 512, height: 512)
                NSApplication.shared.applicationIconImage = image
                break
            }
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                window.titleVisibility = .hidden
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
