import Cocoa
import Quartz
import WebKit

class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    // Supported file extensions
    private static let supportedExtensions = ["mmd", "mermaid", "md", "markdown"]

    // Shared settings via App Group
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.roundrect.mermaidviewer")

    // Shared renderer - initialized with extension bundle
    private static let renderer = MermaidRenderer(bundle: Bundle(for: PreviewProvider.self))

    // MARK: - Settings

    private var theme: String {
        Self.sharedDefaults?.string(forKey: "ql.theme") ?? "default"
    }

    private var sizing: String {
        Self.sharedDefaults?.string(forKey: "ql.sizing") ?? "fit"
    }

    private var darkModeSetting: String {
        Self.sharedDefaults?.string(forKey: "ql.darkMode") ?? "system"
    }

    private var showDebug: Bool {
        Self.sharedDefaults?.bool(forKey: "ql.showDebug") ?? false
    }

    private var backgroundMode: String {
        Self.sharedDefaults?.string(forKey: "ql.backgroundMode") ?? "transparent"
    }

    private var backgroundColor: String {
        Self.sharedDefaults?.string(forKey: "ql.backgroundColor") ?? "#f5f5f5"
    }

    private var mouseMode: String {
        Self.sharedDefaults?.string(forKey: "ql.mouseMode") ?? "pan"
    }

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let fileURL = request.fileURL
        let ext = fileURL.pathExtension.lowercased()

        // Only handle our supported file types
        guard Self.supportedExtensions.contains(ext) else {
            throw NSError(domain: "MermaidQuickLook", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported file type"])
        }

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let mermaidCode: String

        if ext == "md" || ext == "markdown" {
            mermaidCode = extractMermaidFromMarkdown(content)
        } else {
            mermaidCode = content
        }

        // Build render options from settings
        var options = MermaidRenderOptions()
        options.theme = theme
        options.darkModeSetting = darkModeSetting
        options.sizing = sizing
        options.showToolbar = true
        options.showDebug = showDebug
        options.backgroundMode = backgroundMode
        options.backgroundColor = backgroundColor
        options.mouseMode = mouseMode
        options.debugLabel = "Build 13 | Theme: \(theme) | Dark: \(darkModeSetting) | Size: \(sizing) | BG: \(backgroundMode) | Mouse: \(mouseMode)"

        let html = Self.renderer.generateHTML(code: mermaidCode, options: options)

        guard let htmlData = html.data(using: .utf8) else {
            throw NSError(domain: "MermaidQuickLook", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate HTML"])
        }

        // Use a large content size - the HTML will scale the diagram to fit
        let contentSize = CGSize(width: 1200, height: 900)

        return QLPreviewReply(dataOfContentType: .html, contentSize: contentSize) { reply in
            reply.title = fileURL.lastPathComponent
            return htmlData
        }
    }

    private func extractMermaidFromMarkdown(_ markdown: String) -> String {
        let pattern = "```mermaid\\s*\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return "flowchart TD\n    A[No mermaid blocks found]"
        }

        let range = NSRange(markdown.startIndex..., in: markdown)
        let matches = regex.matches(in: markdown, options: [], range: range)

        var mermaidBlocks: [String] = []
        for match in matches {
            if let codeRange = Range(match.range(at: 1), in: markdown) {
                mermaidBlocks.append(String(markdown[codeRange]).trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        if mermaidBlocks.isEmpty {
            return "flowchart TD\n    A[No mermaid blocks found]"
        }

        return mermaidBlocks.first ?? ""
    }
}
