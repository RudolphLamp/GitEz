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
            "/Users/zaza/Documents/icons Zgit/Icon Exports/Icon-iOS-Dark-1024@1x.png",
            "/Users/zaza/Documents/icons Zgit/Icon Exports/Icon-iOS-TintedDark-1024@1x.png",
            "/Users/zaza/Documents/icons Zgit/Icon Exports/Icon-iOS-Default-1024@1x.png",
            "/Users/zaza/Documents/GitEz/ICONS/Icon-iOS-Dark-1024@1x.png"
        ]
        
        for path in iconPaths {
            if FileManager.default.fileExists(atPath: path),
               let sourceImage = NSImage(contentsOfFile: path) {
                let canvasSize = NSSize(width: 512, height: 512)
                let inset: CGFloat = 46
                let drawRect = NSRect(x: inset, y: inset, width: 512 - (inset * 2), height: 512 - (inset * 2))
                
                let dockImage = NSImage(size: canvasSize)
                dockImage.lockFocus()
                let clipPath = NSBezierPath(roundedRect: drawRect, xRadius: 90, yRadius: 90)
                clipPath.addClip()
                sourceImage.draw(in: drawRect)
                dockImage.unlockFocus()
                
                NSApplication.shared.applicationIconImage = dockImage
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
