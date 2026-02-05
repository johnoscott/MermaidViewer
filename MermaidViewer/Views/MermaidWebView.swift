import SwiftUI
import WebKit

struct MermaidWebView: NSViewRepresentable {
    let code: String
    let theme: MermaidTheme
    let isDarkMode: Bool
    let zoomLevel: Double

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.pendingCode = code
        context.coordinator.pendingTheme = theme.rawValue
        context.coordinator.pendingDarkMode = isDarkMode
        context.coordinator.pendingZoom = zoomLevel

        loadHTML(webView: webView, context: context)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Store pending values
        context.coordinator.pendingCode = code
        context.coordinator.pendingTheme = theme.rawValue
        context.coordinator.pendingDarkMode = isDarkMode
        context.coordinator.pendingZoom = zoomLevel

        // Only execute JS if page is loaded
        if context.coordinator.isPageLoaded {
            executeUpdate(webView: webView, context: context)
        }
    }

    private func executeUpdate(webView: WKWebView, context: Context) {
        let escapedCode = context.coordinator.pendingCode
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        let js = """
            updateDiagram(`\(escapedCode)`, '\(context.coordinator.pendingTheme)', \(context.coordinator.pendingDarkMode), \(context.coordinator.pendingZoom));
        """
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("JS Error: \(error)")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func loadHTML(webView: WKWebView, context: Context) {
        guard let mermaidJSURL = Bundle.main.url(forResource: "mermaid.min", withExtension: "js"),
              let mermaidJS = try? String(contentsOf: mermaidJSURL, encoding: .utf8) else {
            print("Could not load mermaid.min.js")
            return
        }

        let html = generateHTML(mermaidJS: mermaidJS, context: context)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func generateHTML(mermaidJS: String, context: Context) -> String {
        let escapedCode = context.coordinator.pendingCode
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        let pendingTheme = context.coordinator.pendingTheme
        let pendingDarkMode = context.coordinator.pendingDarkMode
        let pendingZoom = context.coordinator.pendingZoom

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
                    overflow: hidden;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    transition: background-color 0.3s;
                }
                body.dark { background: #1e1e1e; }
                body.light { background: #f5f5f5; }
                #container {
                    width: 100%;
                    height: 100%;
                    overflow: auto;
                    display: flex;
                    justify-content: center;
                    align-items: flex-start;
                    padding: 20px;
                }
                #diagram {
                    transform-origin: center top;
                    transition: transform 0.2s ease;
                    background: white;
                    border-radius: 8px;
                    padding: 20px;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
                }
                body.dark #diagram {
                    background: #2d2d2d;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
                }
                body.dark #diagram.dark-theme {
                    background: #1a1a2e;
                }
                #error {
                    color: #ff6b6b;
                    padding: 20px;
                    font-family: monospace;
                    white-space: pre-wrap;
                }
                .mermaid { font-family: 'trebuchet ms', verdana, arial, sans-serif; }
            </style>
            <script>\(mermaidJS)</script>
        </head>
        <body class="\(pendingDarkMode ? "dark" : "light")">
            <div id="container">
                <div id="diagram">
                    <div class="mermaid"></div>
                </div>
            </div>
            <script>
                let currentZoom = 1;
                let renderCount = 0;

                function initMermaid(theme) {
                    mermaid.initialize({
                        startOnLoad: false,
                        theme: theme,
                        securityLevel: 'loose',
                        flowchart: { useMaxWidth: false, htmlLabels: true },
                        sequence: { useMaxWidth: false },
                        gantt: { useMaxWidth: false }
                    });
                }

                initMermaid('\(pendingTheme)');

                async function updateDiagram(code, theme, darkMode, zoom) {
                    document.body.className = darkMode ? 'dark' : 'light';
                    currentZoom = zoom;

                    const diagram = document.getElementById('diagram');
                    diagram.style.transform = 'scale(' + zoom + ')';

                    if (theme === 'dark') {
                        diagram.classList.add('dark-theme');
                    } else {
                        diagram.classList.remove('dark-theme');
                    }

                    if (!code || code.trim() === '') {
                        diagram.innerHTML = '<p style="color: #888;">Enter Mermaid code to see diagram</p>';
                        return;
                    }

                    try {
                        initMermaid(theme);
                        renderCount++;
                        const { svg } = await mermaid.render('mermaid-' + renderCount, code);
                        diagram.innerHTML = svg;
                    } catch (e) {
                        diagram.innerHTML = '<div id="error">Error: ' + e.message + '</div>';
                    }
                }

                // Initial render
                updateDiagram(`\(escapedCode)`, '\(pendingTheme)', \(pendingDarkMode), \(pendingZoom));
            </script>
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var webView: WKWebView?
        var isPageLoaded = false
        var pendingCode = ""
        var pendingTheme = "default"
        var pendingDarkMode = false
        var pendingZoom = 1.0
        var parent: MermaidWebView?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
            // Re-render with latest pending values after page load
            let escapedCode = pendingCode
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "")

            let js = """
                updateDiagram(`\(escapedCode)`, '\(pendingTheme)', \(pendingDarkMode), \(pendingZoom));
            """
            webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("JS Error on load: \(error)")
                }
            }
        }
    }
}
