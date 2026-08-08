import SwiftUI

// MARK: - Settings Tabs
private enum SettingsTab: String, CaseIterable {
    case general    = "General"
    case appearance = "Appearance"
    case workflow   = "Workflow"

    var icon: String {
        switch self {
        case .general:    return "person.circle"
        case .appearance: return "paintbrush"
        case .workflow:   return "arrow.triangle.branch"
        }
    }
}

// MARK: - Full Settings Page
struct SettingsPageView: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t

    @AppStorage("appTheme")     private var selectedTheme: AppTheme    = .dark
    @AppStorage("accentPreset") private var accentRaw: String          = AccentPreset.gitez.rawValue

    @State private var activeTab: SettingsTab = .general
    @State private var usernameInput          = ""
    @State private var emailInput             = ""
    @State private var tokenInput             = ""
    @State private var defaultBranch          = "main"

    var body: some View {
        HStack(spacing: 0) {
            // ── Left settings nav ──
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(t.textTertiary)
                    .tracking(0.7)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: { activeTab = tab }) {
                        HStack(spacing: 9) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13))
                                .foregroundColor(activeTab == tab ? t.accent : t.textSecondary)
                                .frame(width: 16)
                            Text(tab.rawValue)
                                .font(.system(size: 13))
                                .foregroundColor(activeTab == tab ? t.textPrimary : t.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(activeTab == tab ? t.accentMuted : Color.clear)
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Back to workspace
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        gitService.currentSection = .workspace
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.system(size: 11))
                        Text("Back")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(t.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 20)
            .frame(width: 200)
            .background(t.sidebar)

            Divider().background(t.divider)

            // ── Right content ──
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    switch activeTab {
                    case .general:    generalSection
                    case .appearance: appearanceSection
                    case .workflow:   workflowSection
                    }
                }
                .padding(40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(t.background)
        }
        .onAppear {
            usernameInput = gitService.gitUser.username
            emailInput    = gitService.gitUser.email
            tokenInput    = gitService.gitUser.token
        }
    }

    // MARK: General
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("General", subtitle: "Manage your GitHub credentials and defaults.")

            VStack(spacing: 0) {
                settingsRow("GitHub Username") {
                    HStack(spacing: 2) {
                        Text("@")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(t.textTertiary)
                        TextField("username", text: $usernameInput)
                            .font(.system(size: 13, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(t.textPrimary)
                            .frame(width: 160)
                    }
                }
                dividerRow

                settingsRow("Email") {
                    TextField("email@example.com", text: $emailInput)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .foregroundColor(t.textPrimary)
                        .frame(width: 200)
                }
                dividerRow

                settingsRow("Personal Access Token") {
                    SecureField("ghp_...", text: $tokenInput)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .foregroundColor(t.textPrimary)
                        .frame(width: 200)
                }
                dividerRow

                settingsRow("Default Branch") {
                    TextField("main", text: $defaultBranch)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .foregroundColor(t.textPrimary)
                        .frame(width: 80)
                }
            }
            .background(t.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 1))

            Button(action: {
                _ = gitService.saveGitUser(username: usernameInput,
                                            email: emailInput,
                                            token: tokenInput)
            }) {
                Text("Save Changes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(t.accent)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Appearance
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            sectionHeader("Appearance",
                          subtitle: "Choose how ZGit looks. Use a built-in theme or make your own.")

            // Color scheme
            VStack(alignment: .leading, spacing: 12) {
                Text("Color scheme")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(t.textPrimary)

                HStack(spacing: 14) {
                    ForEach(AppTheme.allCases) { scheme in
                        ColorSchemeCard(scheme: scheme, isSelected: selectedTheme == scheme) {
                            selectedTheme = scheme
                        }
                    }
                }
            }

            Divider().background(t.divider)

            // Themes / accent picker — T3-style sphere cards
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Themes")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(t.textPrimary)
                    Spacer()
                    Text("Color palette")
                        .font(.system(size: 11))
                        .foregroundColor(t.textTertiary)
                }

                let cols = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(AccentPreset.allCases) { preset in
                        let isSel = accentRaw == preset.rawValue
                        Button(action: { accentRaw = preset.rawValue }) {
                            VStack(alignment: .leading, spacing: 0) {
                                // Sphere pair (T3-style)
                                HStack {
                                    Spacer()
                                    SpherePair(primary: preset.primary, secondary: preset.secondary)
                                        .padding(.vertical, 18)
                                    Spacer()
                                }

                                Rectangle().fill(t.divider).frame(height: 1)

                                HStack {
                                    Text(preset.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(isSel ? t.accent : t.textPrimary)
                                    Spacer()
                                    if isSel {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(t.accent)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .background(t.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSel ? preset.primary.opacity(0.6) : t.border,
                                            lineWidth: isSel ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Workflow
    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("Workflow",
                          subtitle: "Configure your Git workflow preferences.")

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Auto-open Pull Request")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(t.textPrimary)
                        Text("After pushing, automatically open the GitHub PR page.")
                            .font(.system(size: 12))
                            .foregroundColor(t.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $gitService.autoOpenPROnPush)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(16)
            }
            .background(t.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 1))
        }
    }

    // MARK: Helpers
    @ViewBuilder
    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(t.textPrimary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(t.textSecondary)
        }
    }

    @ViewBuilder
    private func settingsRow<C: View>(_ label: String, @ViewBuilder input: () -> C) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(t.textPrimary)
            Spacer()
            input()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var dividerRow: some View {
        Divider()
            .background(t.divider)
            .padding(.horizontal, 16)
    }
}

// MARK: - Color Scheme Card
private struct ColorSchemeCard: View {
    @Environment(\.theme) var t
    let scheme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var isDark: Bool { scheme != .light }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Mini preview
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isDark ? Color(hex: "#111114") : Color(hex: "#F7F7F9"))
                        .frame(width: 110, height: 72)

                    // Sidebar sliver
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isDark ? Color(hex: "#0E0E10") : Color(hex: "#EDEDF0"))
                        .frame(width: 34, height: 72)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 7,
                                bottomLeadingRadius: 7,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 0
                            )
                        )

                    // Fake list rows
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isDark ? Color.white.opacity(i == 0 ? 0.15 : 0.06)
                                             : Color.black.opacity(i == 0 ? 0.1 : 0.04))
                                .frame(width: 44 + CGFloat(i) * 12, height: 5)
                        }
                    }
                    .padding(.leading, 42)

                    // Accent dot
                    Circle()
                        .fill(t.accent)
                        .frame(width: 8, height: 8)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isSelected ? t.accent : t.border,
                                lineWidth: isSelected ? 2 : 1)
                )

                Text(scheme.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? t.textPrimary : t.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - T3-Style Gradient Sphere Pair
struct SpherePair: View {
    let primary: Color
    let secondary: Color
    let size: CGFloat

    init(primary: Color, secondary: Color, size: CGFloat = 52) {
        self.primary = primary
        self.secondary = secondary
        self.size = size
    }

    var body: some View {
        ZStack {
            // Back sphere (secondary / darker)
            sphere(
                colors: [secondary.opacity(0.6), secondary, Color.black.opacity(0.5)],
                highlightOffset: CGSize(width: -size * 0.08, height: -size * 0.18),
                shadow: secondary
            )
            .offset(x: size * 0.36)

            // Front sphere (primary / lighter with white highlight)
            sphere(
                colors: [Color.white.opacity(0.85), primary, secondary.opacity(0.8)],
                highlightOffset: CGSize(width: -size * 0.1, height: -size * 0.2),
                shadow: primary
            )
            .offset(x: -size * 0.2)
        }
        .frame(width: size * 2.0, height: size)
    }

    private func sphere(colors: [Color], highlightOffset: CGSize, shadow: Color) -> some View {
        ZStack {
            // Main gradient fill
            Circle()
                .fill(
                    RadialGradient(
                        colors: colors,
                        center: UnitPoint(x: 0.32, y: 0.25),
                        startRadius: 0,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size, height: size)

            // White gloss highlight
            Ellipse()
                .fill(Color.white.opacity(0.42))
                .frame(width: size * 0.36, height: size * 0.22)
                .blur(radius: 1.5)
                .offset(highlightOffset)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: shadow.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

