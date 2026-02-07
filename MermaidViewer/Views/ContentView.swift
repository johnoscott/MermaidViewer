import SwiftUI

struct ContentView: View {
    @Binding var document: MermaidDocument
    let fileURL: URL?
    @State private var selectedTheme: MermaidTheme = .default
    @State private var isDarkMode: Bool = false
    @State private var zoomLevel: Double = 1.0
    @State private var showEditor: Bool = false

    var body: some View {
        HSplitView {
            // Editor pane (conditionally shown)
            if showEditor {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Mermaid Code")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    TextEditor(text: $document.code)
                        .font(.system(.body, design: .monospaced))
                        .padding(4)
                }
                .frame(minWidth: 300)
            }

            // Preview pane
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Button {
                        withAnimation {
                            showEditor.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                    .help(showEditor ? "Hide Editor" : "Show Editor")
                    .buttonStyle(.bordered)

                    Text("Preview")
                        .font(.headline)

                    Spacer()

                    // Theme picker
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(MermaidTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)

                    // Dark mode toggle
                    Toggle("Dark", isOn: $isDarkMode)
                        .toggleStyle(.switch)

                    Divider()
                        .frame(height: 20)

                    // Zoom controls
                    Button("-") { zoomLevel = max(0.25, zoomLevel - 0.25) }
                        .buttonStyle(.bordered)
                    Text("\(Int(zoomLevel * 100))%")
                        .frame(width: 50)
                    Button("+") { zoomLevel = min(4.0, zoomLevel + 0.25) }
                        .buttonStyle(.bordered)
                    Button("Fit") { zoomLevel = 1.0 }
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                MermaidWebView(
                    code: document.code,
                    theme: selectedTheme,
                    isDarkMode: isDarkMode,
                    zoomLevel: zoomLevel
                )
            }
            .frame(minWidth: 400)
        }
        .frame(minWidth: showEditor ? 800 : 400, minHeight: 500)
        .navigationTitle(windowTitle)
        .onReceive(NotificationCenter.default.publisher(for: .toggleEditor)) { _ in
            withAnimation { showEditor.toggle() }
        }
    }

    private var windowTitle: String {
        guard let url = fileURL else { return "MermaidViewer" }
        return url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

enum MermaidTheme: String, CaseIterable {
    case `default` = "default"
    case forest = "forest"
    case dark = "dark"
    case neutral = "neutral"
    case base = "base"

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .forest: return "Forest"
        case .dark: return "Dark"
        case .neutral: return "Neutral"
        case .base: return "Base"
        }
    }
}

#Preview {
    ContentView(document: .constant(MermaidDocument()), fileURL: nil)
}
