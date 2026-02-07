import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let mermaidDiagram = UTType(exportedAs: "com.mermaid.diagram")
}

struct MermaidDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.mermaidDiagram]

    var code: String

    init(code: String = """
        flowchart TD
            A[Start] --> B{Is it working?}
            B -->|Yes| C[Great!]
            B -->|No| D[Debug]
            D --> B
            C --> E[End]
        """) {
        self.code = code
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.code = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = code.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

@main
struct MermaidViewerApp: App {
    @StateObject private var shortcutManager = ShortcutManager()

    var body: some Scene {
        DocumentGroup(newDocument: MermaidDocument()) { config in
            ContentView(document: config.$document, fileURL: config.fileURL)
        }
        .commands {
            AppCommands(shortcutManager: shortcutManager)
        }

        Settings {
            SettingsView()
                .environmentObject(shortcutManager)
        }
    }
}
