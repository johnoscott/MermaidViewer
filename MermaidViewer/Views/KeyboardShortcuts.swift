import SwiftUI
import AppKit

// MARK: - Shortcut Action

enum ShortcutAction: String, CaseIterable, Identifiable {
    case nextTab
    case previousTab
    case toggleEditor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nextTab: return "Show Next Tab"
        case .previousTab: return "Show Previous Tab"
        case .toggleEditor: return "Toggle Editor"
        }
    }
}

// MARK: - Stored Shortcut

struct StoredShortcut: Codable, Equatable {
    var key: String
    var modifiers: UInt

    var keyEquivalent: KeyEquivalent {
        switch key {
        case "\t": return .tab
        case "\r", "\n": return .return
        case " ": return .space
        case "\u{7F}": return .delete
        case "\u{1B}": return .escape
        case "\u{F700}": return .upArrow
        case "\u{F701}": return .downArrow
        case "\u{F702}": return .leftArrow
        case "\u{F703}": return .rightArrow
        default:
            guard let char = key.first else { return KeyEquivalent("?") }
            return KeyEquivalent(char)
        }
    }

    var eventModifiers: EventModifiers {
        var result: EventModifiers = []
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.command) { result.insert(.command) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.control) { result.insert(.control) }
        return result
    }

    var displayString: String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(keyDisplayName)
        return parts.joined()
    }

    private var keyDisplayName: String {
        switch key {
        case "\t": return "⇥"
        case "\r", "\n": return "↩"
        case " ": return "Space"
        case "\u{7F}": return "⌫"
        case "\u{1B}": return "⎋"
        case "\u{F700}": return "↑"
        case "\u{F701}": return "↓"
        case "\u{F702}": return "←"
        case "\u{F703}": return "→"
        default: return key.uppercased()
        }
    }
}

// MARK: - Shortcut Manager

class ShortcutManager: ObservableObject {
    static let defaultShortcuts: [String: StoredShortcut] = [
        ShortcutAction.nextTab.rawValue: StoredShortcut(
            key: "\t",
            modifiers: NSEvent.ModifierFlags.control.rawValue
        ),
        ShortcutAction.previousTab.rawValue: StoredShortcut(
            key: "\t",
            modifiers: NSEvent.ModifierFlags([.control, .shift]).rawValue
        ),
        ShortcutAction.toggleEditor.rawValue: StoredShortcut(
            key: "1",
            modifiers: NSEvent.ModifierFlags.command.rawValue
        ),
    ]

    @Published var shortcuts: [String: StoredShortcut] {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "keyboardShortcuts"),
           let saved = try? JSONDecoder().decode([String: StoredShortcut].self, from: data) {
            self.shortcuts = saved
        } else {
            self.shortcuts = Self.defaultShortcuts
        }
    }

    func shortcut(for action: ShortcutAction) -> StoredShortcut {
        shortcuts[action.rawValue] ?? Self.defaultShortcuts[action.rawValue]!
    }

    func setShortcut(_ shortcut: StoredShortcut, for action: ShortcutAction) {
        shortcuts[action.rawValue] = shortcut
    }

    func resetShortcut(for action: ShortcutAction) {
        shortcuts[action.rawValue] = Self.defaultShortcuts[action.rawValue]!
    }

    func resetAll() {
        shortcuts = Self.defaultShortcuts
    }

    func isDefault(for action: ShortcutAction) -> Bool {
        shortcut(for: action) == Self.defaultShortcuts[action.rawValue]!
    }

    private func save() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: "keyboardShortcuts")
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let toggleEditor = Notification.Name("toggleEditor")
}

// MARK: - App Commands

struct AppCommands: Commands {
    var shortcutManager: ShortcutManager

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            let s = shortcutManager.shortcut(for: .toggleEditor)
            Button("Toggle Editor") {
                NotificationCenter.default.post(name: .toggleEditor, object: nil)
            }
            .keyboardShortcut(s.keyEquivalent, modifiers: s.eventModifiers)
        }

        CommandGroup(after: .windowArrangement) {
            let nextS = shortcutManager.shortcut(for: .nextTab)
            Button("Show Next Tab") {
                NSApp.sendAction(#selector(NSWindow.selectNextTab(_:)), to: nil, from: nil)
            }
            .keyboardShortcut(nextS.keyEquivalent, modifiers: nextS.eventModifiers)

            let prevS = shortcutManager.shortcut(for: .previousTab)
            Button("Show Previous Tab") {
                NSApp.sendAction(#selector(NSWindow.selectPreviousTab(_:)), to: nil, from: nil)
            }
            .keyboardShortcut(prevS.keyEquivalent, modifiers: prevS.eventModifiers)
        }
    }
}

// MARK: - Shortcut Recorder Button

struct ShortcutRecorderButton: View {
    let action: ShortcutAction
    @ObservedObject var manager: ShortcutManager
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                if isRecording {
                    Text("Type shortcut\u{2026}")
                        .foregroundColor(.accentColor)
                        .frame(minWidth: 100)
                } else {
                    Text(manager.shortcut(for: action).displayString)
                        .font(.system(.body, design: .monospaced))
                        .frame(minWidth: 100)
                }
            }
            .buttonStyle(.bordered)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 2)
            )

            Button {
                manager.resetShortcut(for: action)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Reset to default")
            .opacity(manager.isDefault(for: action) ? 0.3 : 1.0)
            .disabled(manager.isDefault(for: action))
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape cancels
                self.stopRecording()
                return nil
            }

            let relevantFlags: NSEvent.ModifierFlags = [.command, .shift, .control, .option]
            let mods = event.modifierFlags.intersection(relevantFlags)

            // Require at least one of command, control, option
            guard !mods.intersection([.command, .control, .option]).isEmpty else {
                return nil
            }

            let key = event.charactersIgnoringModifiers ?? ""
            guard !key.isEmpty else { return nil }

            self.manager.setShortcut(StoredShortcut(key: key, modifiers: mods.rawValue), for: self.action)
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

// MARK: - Keyboard Shortcuts Settings View

struct KeyboardShortcutsSettingsView: View {
    @ObservedObject var manager: ShortcutManager

    var body: some View {
        HStack(spacing: 0) {
            // Settings panel
            VStack(alignment: .leading, spacing: 20) {
                Text("Keyboard Shortcuts")
                    .font(.headline)

                VStack(spacing: 0) {
                    ForEach(ShortcutAction.allCases) { action in
                        HStack {
                            Text(action.displayName)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ShortcutRecorderButton(action: action, manager: manager)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if action != ShortcutAction.allCases.last {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )

                Text("Click a shortcut to record a new combination. Press Esc to cancel.\nShortcuts require at least one modifier key (\u{2318}, \u{2325}, or \u{2303}).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)

                Spacer()

                HStack {
                    Spacer()
                    Button("Reset All to Defaults") {
                        manager.resetAll()
                    }
                }
            }
            .padding(20)
            .frame(width: 420)

            Divider()

            // Right panel
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "keyboard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor.opacity(0.5))
                Text("Keyboard Shortcuts")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("Customise shortcuts to match\nyour workflow.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}
