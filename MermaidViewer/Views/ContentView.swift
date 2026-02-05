import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTheme: MermaidTheme = .default
    @State private var isDarkMode: Bool = false
    @State private var zoomLevel: Double = 1.0

    var body: some View {
        HSplitView {
            // Editor pane
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Mermaid Code")
                        .font(.headline)
                    Spacer()
                    Button("Load File...") {
                        loadFile()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                TextEditor(text: $appState.mermaidCode)
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
            }
            .frame(minWidth: 300)

            // Preview pane
            VStack(spacing: 0) {
                // Toolbar
                HStack {
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
                    code: appState.mermaidCode,
                    theme: selectedTheme,
                    isDarkMode: isDarkMode,
                    zoomLevel: zoomLevel
                )
            }
            .frame(minWidth: 400)
        }
        .frame(minWidth: 800, minHeight: 500)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func loadFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "mmd")!,
            UTType(filenameExtension: "mermaid")!,
            UTType(filenameExtension: "md")!
        ]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            appState.loadFile(url: url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        self.appState.loadFile(url: url)
                    }
                }
            }
        }
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
    ContentView()
        .environmentObject(AppState.shared)
}
