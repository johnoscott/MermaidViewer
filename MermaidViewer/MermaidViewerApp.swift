import SwiftUI
import UniformTypeIdentifiers

@main
struct MermaidViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "mmd")!,
            UTType(filenameExtension: "mermaid")!,
            UTType(filenameExtension: "md")!
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            appState.loadFile(url: url)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            let ext = url.pathExtension.lowercased()
            if ["mmd", "mermaid", "md", "markdown"].contains(ext) {
                AppState.shared.loadFile(url: url)
                break
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check if launched with a file
        if let fileURL = UserDefaults.standard.url(forKey: "launchFileURL") {
            AppState.shared.loadFile(url: fileURL)
            UserDefaults.standard.removeObject(forKey: "launchFileURL")
        }
    }
}

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var currentFileURL: URL?
    @Published var mermaidCode: String = """
        flowchart TD
            A[Start] --> B{Is it working?}
            B -->|Yes| C[Great!]
            B -->|No| D[Debug]
            D --> B
            C --> E[End]
        """

    func loadFile(url: URL) {
        currentFileURL = url
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            if url.pathExtension.lowercased() == "md" {
                mermaidCode = extractMermaidFromMarkdown(content)
            } else {
                mermaidCode = content
            }
        } catch {
            print("Error loading file: \(error)")
        }
    }

    private func extractMermaidFromMarkdown(_ markdown: String) -> String {
        let pattern = "```mermaid\\s*\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return markdown
        }

        let range = NSRange(markdown.startIndex..., in: markdown)
        let matches = regex.matches(in: markdown, options: [], range: range)

        var mermaidBlocks: [String] = []
        for match in matches {
            if let codeRange = Range(match.range(at: 1), in: markdown) {
                mermaidBlocks.append(String(markdown[codeRange]).trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        return mermaidBlocks.isEmpty ? markdown : mermaidBlocks.joined(separator: "\n\n---\n\n")
    }
}
