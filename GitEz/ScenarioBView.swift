import SwiftUI

// MARK: - Diff Data Models
struct DiffFile: Identifiable {
    let id = UUID()
    let filename: String
    var lines: [DiffLine]
}

struct DiffLine: Identifiable {
    let id = UUID()
    enum LineKind { case added, removed, context, hunk }
    let content: String
    let kind: LineKind
}

// MARK: - Diff Parser
private func parseDiff(_ raw: String) -> [DiffFile] {
    var files: [DiffFile] = []
    var currentFile: DiffFile?

    for line in raw.components(separatedBy: "\n") {
        if line.hasPrefix("diff --git ") {
            if let f = currentFile { files.append(f) }
            let parts = line.components(separatedBy: " b/")
            let name = parts.last ?? "unknown"
            currentFile = DiffFile(filename: name, lines: [])
        } else if line.hasPrefix("@@") {
            currentFile?.lines.append(DiffLine(content: line, kind: .hunk))
        } else if line.hasPrefix("+") && !line.hasPrefix("+++") {
            currentFile?.lines.append(DiffLine(content: String(line.dropFirst()), kind: .added))
        } else if line.hasPrefix("-") && !line.hasPrefix("---") {
            currentFile?.lines.append(DiffLine(content: String(line.dropFirst()), kind: .removed))
        } else if !line.hasPrefix("index ") && !line.hasPrefix("---") && !line.hasPrefix("+++") && !line.hasPrefix("diff") {
            if !line.isEmpty {
                currentFile?.lines.append(DiffLine(content: line, kind: .context))
            }
        }
    }
    if let f = currentFile { files.append(f) }
    return files
}

// MARK: - Code Diff View
struct CodeDiffView: View {
    @EnvironmentObject var gitService: GitService
    @Environment(\.theme) var t

    var parsedFiles: [DiffFile] { parseDiff(gitService.fileDiff) }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(t.textSecondary)
                Text("Changes")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(t.textSecondary)

                if !parsedFiles.isEmpty {
                    Text("\(parsedFiles.count) file\(parsedFiles.count == 1 ? "" : "s")")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(t.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(t.surfaceElevated)
                        .cornerRadius(4)
                }

                Spacer()

                Button(action: { gitService.fetchDiff() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(t.textSecondary)
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { gitService.showDiffViewer = false }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(t.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(t.surface)

            Divider().background(t.divider)

            if gitService.fileDiff.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(t.textTertiary)
                        Text("Working tree clean — no changes to show")
                            .font(.system(size: 12))
                            .foregroundColor(t.textTertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 28)
                .background(t.terminalBg)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(parsedFiles) { file in
                            DiffFileSection(file: file)
                        }
                    }
                }
                .frame(height: 240)
                .background(t.terminalBg)
            }
        }
    }
}

// MARK: - Diff File Section
private struct DiffFileSection: View {
    @Environment(\.theme) var t
    let file: DiffFile
    @State private var expanded = true

    var addedCount: Int { file.lines.filter { $0.kind == .added }.count }
    var removedCount: Int { file.lines.filter { $0.kind == .removed }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(t.textTertiary)

                    Text(file.filename)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(t.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    if addedCount > 0 {
                        Text("+\(addedCount)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(t.codeAddedFg)
                    }
                    if removedCount > 0 {
                        Text("-\(removedCount)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(t.codeRemovedFg)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(t.surface.opacity(0.25))
            }
            .buttonStyle(.plain)

            Divider().background(t.divider.opacity(0.5))

            // Diff lines
            if expanded {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(file.lines) { line in
                        DiffLineView(line: line)
                    }
                }
            }
        }
    }
}

// MARK: - Diff Line View
private struct DiffLineView: View {
    @Environment(\.theme) var t
    let line: DiffLine

    var body: some View {
        HStack(spacing: 0) {
            // Gutter marker
            Text(gutter)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(gutterColor)
                .frame(width: 20)
                .padding(.vertical, 1)

            Text(line.content)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(lineColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 1)
        }
        .padding(.horizontal, 10)
        .background(lineBg)
    }

    var gutter: String {
        switch line.kind {
        case .added:   return "+"
        case .removed: return "−"
        case .hunk:    return "@@"
        case .context: return ""
        }
    }

    var gutterColor: Color {
        switch line.kind {
        case .added:   return t.codeAddedFg
        case .removed: return t.codeRemovedFg
        case .hunk:    return t.accent.opacity(0.7)
        case .context: return t.textTertiary
        }
    }

    var lineColor: Color {
        switch line.kind {
        case .added:   return t.codeAddedFg
        case .removed: return t.codeRemovedFg
        case .hunk:    return t.textTertiary
        case .context: return t.textSecondary
        }
    }

    var lineBg: Color {
        switch line.kind {
        case .added:   return t.codeAdded
        case .removed: return t.codeRemoved
        case .hunk:    return t.accent.opacity(0.07)
        case .context: return .clear
        }
    }
}
