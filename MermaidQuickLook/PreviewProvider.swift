import Cocoa
import Quartz
import WebKit

class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    // Supported file extensions
    private static let supportedExtensions = ["mmd", "mermaid", "md", "markdown"]

    // Shared settings via App Group
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.mermaid.viewer")

    // Bundled mermaid.js - loaded from extension bundle
    private static let mermaidJS: String = {
        let bundle = Bundle(for: PreviewProvider.self)

        if let url = bundle.url(forResource: "mermaid.min", withExtension: "js"),
           let js = try? String(contentsOf: url, encoding: .utf8) {
            return js
        }

        // Fallback - return a minimal error message
        return "console.error('mermaid.min.js not found');"
    }()

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

        let html = generatePreviewHTML(code: mermaidCode, filename: fileURL.lastPathComponent)

        guard let htmlData = html.data(using: .utf8) else {
            throw NSError(domain: "MermaidQuickLook", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate HTML"])
        }

        let contentSize = CGSize(width: 800, height: 600)

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

    private func generatePreviewHTML(code: String, filename: String) -> String {
        let escapedCode = code
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        // Sizing CSS based on settings
        let sizingCSS: String
        switch sizing {
        case "expandVertical":
            sizingCSS = "#diagram { height: 100vh; } .mermaid svg { height: 100%; width: auto; }"
        case "expandHorizontal":
            sizingCSS = "#diagram { width: 100%; } .mermaid svg { width: 100%; height: auto; }"
        case "original":
            sizingCSS = ""
        default: // fit
            sizingCSS = "#diagram { max-width: 100%; max-height: 100%; } .mermaid svg { max-width: 100%; max-height: 100%; }"
        }

        // Dark mode handling
        let darkModeJS: String
        switch darkModeSetting {
        case "light":
            darkModeJS = "false"
        case "dark":
            darkModeJS = "true"
        default: // system
            darkModeJS = "window.matchMedia('(prefers-color-scheme: dark)').matches"
        }

        // Theme for mermaid - use dark theme if dark mode is forced, or match system
        let mermaidTheme = theme == "default" ? "default" : theme

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    padding: 20px;
                    transition: background-color 0.3s;
                }
                body.light { background: #f5f5f5; }
                body.dark { background: #1e1e1e; }
                #diagram {
                    border-radius: 12px;
                    padding: 24px;
                    max-width: 100%;
                    overflow: auto;
                    transition: all 0.3s;
                }
                body.light #diagram {
                    background: white;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
                }
                body.dark #diagram {
                    background: #2d2d2d;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
                }
                #error {
                    color: #ff6b6b;
                    font-family: ui-monospace, monospace;
                    white-space: pre-wrap;
                    padding: 20px;
                    background: rgba(255,107,107,0.1);
                    border-radius: 8px;
                }
                .mermaid {
                    font-family: 'trebuchet ms', verdana, arial, sans-serif;
                }
                \(sizingCSS)
            </style>
            <script>
            \(Self.mermaidJS)
            </script>
        </head>
        <body>
            <div id="diagram">
                <pre class="mermaid">\(escapedCode)</pre>
            </div>
            <script>
                const isDark = \(darkModeJS);
                document.body.className = isDark ? 'dark' : 'light';

                // Determine theme: use user setting, but if 'default', auto-switch based on dark mode
                let selectedTheme = '\(mermaidTheme)';
                if (selectedTheme === 'default' && isDark) {
                    selectedTheme = 'dark';
                }

                try {
                    mermaid.initialize({
                        startOnLoad: true,
                        theme: selectedTheme,
                        securityLevel: 'loose',
                        flowchart: { useMaxWidth: true, htmlLabels: true },
                        sequence: { useMaxWidth: true },
                        gantt: { useMaxWidth: true }
                    });
                } catch (e) {
                    document.getElementById('diagram').innerHTML = '<div id="error">Error: ' + e.message + '</div>';
                }
            </script>
        </body>
        </html>
        """
    }
}
