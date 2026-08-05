import SwiftUI

// MARK: - Native macOS Visual Effect View (Liquid Glass Vibrancy)
public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let nsView = NSVisualEffectView()
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        return nsView
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Liquid Glass Card Modifier
public struct LiquidGlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 20
    public var paddingAmount: CGFloat = 24
    
    public func body(content: Content) -> some View {
        content
            .padding(paddingAmount)
            .background(
                ZStack {
                    VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                    Color.white.opacity(0.08)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.08),
                                Color.blue.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

extension View {
    public func liquidGlassCard(cornerRadius: CGFloat = 20, paddingAmount: CGFloat = 24) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, paddingAmount: paddingAmount))
    }
}
