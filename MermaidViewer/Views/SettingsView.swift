import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject var shortcutManager: ShortcutManager

    // Quick Look Settings (stored in shared UserDefaults for extension access)
    @AppStorage("ql.theme", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))
    private var qlTheme: String = "default"

    @AppStorage("ql.sizing", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))
    private var qlSizing: String = "fit"

    @AppStorage("ql.darkMode", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))
    private var qlDarkMode: String = "system"

    @AppStorage("ql.backgroundMode", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))
    private var qlBackgroundMode: String = "transparent"

    @AppStorage("ql.backgroundColor", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))
    private var qlBackgroundColor: String = "#f5f5f5"

    @AppStorage("ql.showDebug", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))
    private var qlShowDebug: Bool = false

    @AppStorage("ql.mouseMode", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))
    private var qlMouseMode: String = "pan"

    @State private var backgroundColor: Color = Color(hex: "#f5f5f5") ?? .gray

    @Environment(\.colorScheme) private var systemColorScheme

    // State for tracking changes
    @State private var settingsApplied = true
    @State private var isApplying = false

    // Thumbnail Settings
    @AppStorage("thumbnail.enabled") private var thumbnailEnabled: Bool = true
    @AppStorage("thumbnail.style") private var thumbnailStyle: String = "diagram"

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

            KeyboardShortcutsSettingsView(manager: shortcutManager)
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 800, height: 450)
    }

    private var quickLookSettingsTab: some View {
        HStack(spacing: 0) {
            // Settings Panel - compact grid layout
            VStack(alignment: .leading, spacing: 16) {
                // Theme & Appearance Row
                HStack(alignment: .top, spacing: 24) {
                    // Theme
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Theme")
                            .font(.headline)
                        Picker("", selection: $qlTheme) {
                            Text("Default").tag("default")
                            Text("Dark").tag("dark")
                            Text("Forest").tag("forest")
                            Text("Neutral").tag("neutral")
                            Text("Base").tag("base")
                        }
                        .labelsHidden()
                        .frame(width: 120)
                    }

                    // Dark Mode
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Appearance")
                            .font(.headline)
                        Picker("", selection: $qlDarkMode) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }
                }

                // Sizing & Mouse Mode Row
                HStack(alignment: .top, spacing: 24) {
                    // Sizing
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sizing")
                            .font(.headline)
                        Picker("", selection: $qlSizing) {
                            Text("Fit to Window").tag("fit")
                            Text("Expand Vertical").tag("expandVertical")
                            Text("Expand Horizontal").tag("expandHorizontal")
                            Text("Original Size").tag("original")
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }

                    // Mouse Mode
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mouse")
                            .font(.headline)
                        Picker("", selection: $qlMouseMode) {
                            Label("Pan", systemImage: "hand.raised.fill").tag("pan")
                            Label("Select", systemImage: "cursorarrow").tag("select")
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }
                }

                // Background Row
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Background")
                            .font(.headline)
                        HStack(spacing: 12) {
                            Picker("", selection: $qlBackgroundMode) {
                                Text("Transparent").tag("transparent")
                                Text("Solid").tag("opaque")
                            }
                            .labelsHidden()
                            .frame(width: 120)

                            if qlBackgroundMode == "opaque" {
                                ColorPicker("", selection: $backgroundColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .frame(width: 44)
                                    .onChange(of: backgroundColor) { newColor in
                                        qlBackgroundColor = newColor.hexString
                                    }
                            }
                        }
                    }

                    // Debug toggle
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Developer")
                            .font(.headline)
                        Toggle("Debug Info", isOn: $qlShowDebug)
                            .toggleStyle(.checkbox)
                    }
                }

                Spacer()

                // Apply button
                HStack {
                    Button(action: applySettings) {
                        HStack(spacing: 6) {
                            if isApplying {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: settingsApplied ? "checkmark.circle.fill" : "arrow.clockwise")
                                    .foregroundColor(settingsApplied ? .green : .accentColor)
                            }
                            Text(settingsApplied ? "Applied" : "Apply to Finder")
                        }
                    }
                    .disabled(settingsApplied || isApplying)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    if !settingsApplied {
                        Text("Restart Quick Look to see changes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .frame(width: 320)
            .onChange(of: qlTheme) { _ in settingsApplied = false }
            .onChange(of: qlDarkMode) { _ in settingsApplied = false }
            .onChange(of: qlSizing) { _ in settingsApplied = false }
            .onChange(of: qlShowDebug) { _ in settingsApplied = false }
            .onChange(of: qlBackgroundMode) { _ in settingsApplied = false }
            .onChange(of: qlBackgroundColor) { _ in settingsApplied = false }
            .onChange(of: qlMouseMode) { _ in settingsApplied = false }
            .onAppear {
                backgroundColor = Color(hex: qlBackgroundColor) ?? .gray
            }

            Divider()

            // Preview Panel
            VStack(alignment: .leading, spacing: 0) {
                Text("Preview")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                SettingsPreviewWebView(
                    code: sampleDiagram,
                    theme: qlTheme,
                    darkModeSetting: qlDarkMode,
                    systemColorScheme: systemColorScheme,
                    sizing: qlSizing
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }

    private var thumbnailSettingsTab: some View {
        HStack(spacing: 0) {
            // Settings
            VStack(alignment: .leading, spacing: 16) {
                Text("Thumbnail Generation")
                    .font(.headline)

                Toggle("Generate thumbnails for .mmd files", isOn: $thumbnailEnabled)
                    .toggleStyle(.checkbox)

                if thumbnailEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("", selection: $thumbnailStyle) {
                            Text("Rendered Diagram").tag("diagram")
                            Text("Document Icon").tag("icon")
                        }
                        .labelsHidden()
                        .pickerStyle(.radioGroup)
                    }
                    .padding(.leading, 20)
                }

                Spacer()

                Text("Thumbnails show a preview of your Mermaid diagram in Finder.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .frame(width: 320)

            Divider()

            // Preview
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: thumbnailEnabled ? "doc.richtext" : "doc")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 100)
                        .foregroundColor(.blue)

                    Text(thumbnailEnabled ? "With Thumbnail" : "No Thumbnail")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }

    private func applySettings() {
        isApplying = true

        DispatchQueue.global(qos: .userInitiated).async {
            let qlmanage = Process()
            qlmanage.executableURL = URL(fileURLWithPath: "/usr/bin/qlmanage")
            qlmanage.arguments = ["-r"]
            try? qlmanage.run()
            qlmanage.waitUntilExit()

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
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                // App info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Application")
                        .font(.headline)
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                        GridRow {
                            Text("Mermaid Viewer")
                            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                                .foregroundColor(.secondary)
                        }
                        GridRow {
                            Text("Mermaid.js")
                            Text("v11.x (bundled)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.system(.body, design: .default))
                }

                // Extension status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Look Extension")
                        .font(.headline)
                    HStack {
                        Text("Status:")
                        Text("Registered")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }

                // Usage
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Press Space on any .mmd or .mermaid file in Finder")
                        Text("• Supported: .mmd, .mermaid, .md (with mermaid blocks)")
                        Text("• App must remain installed for Quick Look to work")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(20)
            .frame(width: 320)

            Divider()

            // Logo/branding area
            VStack {
                Spacer()
                Image(systemName: "flowchart.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor.opacity(0.6))
                Text("Mermaid Viewer")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

// MARK: - Settings Preview WebView

struct SettingsPreviewWebView: NSViewRepresentable {
    let code: String
    let theme: String
    let darkModeSetting: String
    let systemColorScheme: ColorScheme
    let sizing: String

    private static let renderer = MermaidRenderer(bundle: Bundle.main)

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
        var options = MermaidRenderOptions()
        options.theme = theme
        options.darkModeSetting = darkModeSetting
        options.sizing = sizing
        options.showToolbar = true
        options.showDebug = false

        let systemIsDark = systemColorScheme == .dark
        let html = Self.renderer.generateHTML(code: code, options: options, systemIsDark: systemIsDark)
        webView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ShortcutManager())
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return "#808080" }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
