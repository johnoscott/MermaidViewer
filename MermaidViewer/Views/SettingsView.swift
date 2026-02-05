import SwiftUI
import WebKit

struct SettingsView: View {
    // Quick Look Settings (stored in shared UserDefaults for extension access)
    @AppStorage("ql.theme", store: UserDefaults(suiteName: "group.com.mermaid.viewer"))
    private var qlTheme: String = "default"

    @AppStorage("ql.sizing", store: UserDefaults(suiteName: "group.com.mermaid.viewer"))
    private var qlSizing: String = "fit"

    @AppStorage("ql.darkMode", store: UserDefaults(suiteName: "group.com.mermaid.viewer"))
    private var qlDarkMode: String = "system"  // "system", "light", "dark"

    @AppStorage("ql.backgroundColor", store: UserDefaults(suiteName: "group.com.mermaid.viewer"))
    private var qlBackgroundColor: String = "#f5f5f5"

    @Environment(\.colorScheme) private var systemColorScheme

    // State for tracking changes
    @State private var settingsApplied = true
    @State private var isApplying = false

    // Thumbnail Settings
    @AppStorage("thumbnail.enabled") private var thumbnailEnabled: Bool = true
    @AppStorage("thumbnail.style") private var thumbnailStyle: String = "diagram"

    // App Settings
    @AppStorage("defaultTheme") private var defaultTheme: String = "default"
    @AppStorage("autoRefresh") private var autoRefresh: Bool = true

    private let sampleDiagram = """
        flowchart TD
            A[Start] --> B{Decision}
            B -->|Yes| C[Action 1]
            B -->|No| D[Action 2]
            C --> E[End]
            D --> E
        """

    var body: some View {
        TabView {
            quickLookSettingsTab
                .tabItem {
                    Label("Quick Look", systemImage: "eye")
                }

            thumbnailSettingsTab
                .tabItem {
                    Label("Thumbnails", systemImage: "photo")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 600, height: 500)
    }

    private var quickLookSettingsTab: some View {
        HSplitView {
            // Settings Panel
            VStack(spacing: 0) {
                Form {
                    Section("Theme") {
                        Picker("Diagram Theme", selection: $qlTheme) {
                            Text("Default").tag("default")
                            Text("Dark").tag("dark")
                            Text("Forest").tag("forest")
                            Text("Neutral").tag("neutral")
                            Text("Base").tag("base")
                        }
                        .pickerStyle(.radioGroup)
                    }

                    Section("Appearance") {
                        Picker("Background Mode", selection: $qlDarkMode) {
                            Text("Match System").tag("system")
                            Text("Always Light").tag("light")
                            Text("Always Dark").tag("dark")
                        }
                        .pickerStyle(.radioGroup)
                    }

                    Section("Sizing") {
                        Picker("Diagram Sizing", selection: $qlSizing) {
                            Text("Fit to Window").tag("fit")
                            Text("Expand Vertically").tag("expandVertical")
                            Text("Expand Horizontally").tag("expandHorizontal")
                            Text("Original Size").tag("original")
                        }
                        .pickerStyle(.radioGroup)
                    }
                }
                .formStyle(.grouped)

                Divider()

                // Apply button at bottom - always visible
                VStack(spacing: 8) {
                    Button(action: applySettings) {
                        HStack {
                            if isApplying {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: settingsApplied ? "checkmark.circle.fill" : "arrow.clockwise")
                            }
                            Text(settingsApplied ? "Settings Applied" : "Apply to Finder")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(settingsApplied || isApplying)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("Click to apply settings to Finder Quick Look")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .frame(minWidth: 220, maxWidth: 260)
            .onChange(of: qlTheme) { _ in settingsApplied = false }
            .onChange(of: qlDarkMode) { _ in settingsApplied = false }
            .onChange(of: qlSizing) { _ in settingsApplied = false }

            // Preview Panel
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)

                SettingsPreviewWebView(
                    code: sampleDiagram,
                    theme: qlTheme,
                    darkModeSetting: qlDarkMode,
                    systemColorScheme: systemColorScheme,
                    sizing: qlSizing
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
    }

    private var thumbnailSettingsTab: some View {
        Form {
            Section("Thumbnail Generation") {
                Toggle("Generate Thumbnails for .mmd Files", isOn: $thumbnailEnabled)

                if thumbnailEnabled {
                    Picker("Thumbnail Style", selection: $thumbnailStyle) {
                        Text("Rendered Diagram").tag("diagram")
                        Text("Document Icon").tag("icon")
                    }
                    .pickerStyle(.radioGroup)

                    Text("Thumbnails show a preview of your Mermaid diagram in Finder.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Preview") {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: thumbnailEnabled ? "doc.richtext" : "doc")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 80)
                            .foregroundColor(.blue)

                        Text(thumbnailEnabled ? "With Thumbnail" : "No Thumbnail")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .formStyle(.grouped)
    }

    private func applySettings() {
        isApplying = true

        DispatchQueue.global(qos: .userInitiated).async {
            // Settings are automatically synced via App Group UserDefaults
            // Just need to restart Quick Look to pick up changes

            // Reset Quick Look cache
            let qlmanage = Process()
            qlmanage.executableURL = URL(fileURLWithPath: "/usr/bin/qlmanage")
            qlmanage.arguments = ["-r"]
            try? qlmanage.run()
            qlmanage.waitUntilExit()

            // Kill Quick Look services to force reload
            let killQL = Process()
            killQL.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            killQL.arguments = ["-9", "QuickLookUIService"]
            try? killQL.run()
            killQL.waitUntilExit()

            DispatchQueue.main.async {
                isApplying = false
                settingsApplied = true
            }
        }
    }

    private var aboutTab: some View {
        Form {
            Section("Application") {
                HStack {
                    Text("Mermaid Viewer")
                    Spacer()
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Mermaid.js")
                    Spacer()
                    Text("v11.x (bundled)")
                        .foregroundColor(.secondary)
                }
            }

            Section("Quick Look Extension") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text("Registered")
                        .foregroundColor(.green)
                }

                Text("Press Space on any .mmd or .mermaid file in Finder to preview.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Usage") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This application provides Quick Look previews for Mermaid diagram files.")
                    Text("Supported file types: .mmd, .mermaid")
                    Text("The app must remain installed for Quick Look to work.")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Settings Preview WebView

struct SettingsPreviewWebView: NSViewRepresentable {
    let code: String
    let theme: String
    let darkModeSetting: String
    let systemColorScheme: ColorScheme
    let sizing: String

    private var isDarkMode: Bool {
        switch darkModeSetting {
        case "light": return false
        case "dark": return true
        default: return systemColorScheme == .dark
        }
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        loadPreview(webView: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        loadPreview(webView: webView)
    }

    private func loadPreview(webView: WKWebView) {
        guard let mermaidJSURL = Bundle.main.url(forResource: "mermaid.min", withExtension: "js"),
              let mermaidJS = try? String(contentsOf: mermaidJSURL, encoding: .utf8) else {
            return
        }

        let escapedCode = code
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")

        let sizingCSS: String
        switch sizing {
        case "expandVertical":
            sizingCSS = "height: 100%; width: auto;"
        case "expandHorizontal":
            sizingCSS = "width: 100%; height: auto;"
        case "original":
            sizingCSS = ""
        default: // fit
            sizingCSS = "max-width: 100%; max-height: 100%;"
        }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    overflow: auto;
                    background: \(isDarkMode ? "#1e1e1e" : "#f5f5f5");
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    padding: 10px;
                }
                #diagram {
                    background: \(isDarkMode ? "#2d2d2d" : "white");
                    border-radius: 8px;
                    padding: 16px;
                    box-shadow: 0 2px 10px rgba(0, 0, 0, \(isDarkMode ? "0.4" : "0.1"));
                    \(sizingCSS)
                }
                .mermaid svg {
                    \(sizingCSS)
                }
            </style>
            <script>\(mermaidJS)</script>
        </head>
        <body>
            <div id="diagram">
                <div class="mermaid"></div>
            </div>
            <script>
                mermaid.initialize({
                    startOnLoad: false,
                    theme: '\(theme)',
                    securityLevel: 'loose'
                });
                (async () => {
                    try {
                        const { svg } = await mermaid.render('preview', `\(escapedCode)`);
                        document.querySelector('.mermaid').innerHTML = svg;
                    } catch (e) {
                        document.querySelector('.mermaid').innerHTML = '<p style="color:red">' + e.message + '</p>';
                    }
                })();
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    SettingsView()
}
