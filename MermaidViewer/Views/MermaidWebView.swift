import SwiftUI
import WebKit

private class NonInteractiveWebView: WKWebView {
    override var acceptsFirstResponder: Bool { false }
}

struct MermaidWebView: NSViewRepresentable {
    let code: String
    let theme: MermaidTheme
    let isDarkMode: Bool
    let zoomLevel: Double

    // Shared renderer using main bundle
    private static let renderer = MermaidRenderer(bundle: Bundle.main)

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = NonInteractiveWebView(frame: .zero, configuration: configuration)
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
        var options = MermaidRenderOptions()
        options.theme = context.coordinator.pendingTheme
        options.darkModeSetting = context.coordinator.pendingDarkMode ? "dark" : "light"

        let html = Self.renderer.generateEditorHTML(
            code: context.coordinator.pendingCode,
            options: options,
            systemIsDark: context.coordinator.pendingDarkMode,
            zoomLevel: context.coordinator.pendingZoom
        )
        webView.loadHTMLString(html, baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var webView: WKWebView?
        var isPageLoaded = false
        var pendingCode = ""
        var pendingTheme = "default"
        var pendingDarkMode = false
        var pendingZoom = 1.0

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
