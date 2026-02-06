# Mermaid Viewer - Developer Guide

## Project Structure

```
MermaidQuickLook/
├── MermaidViewer/           # Main application
│   ├── MermaidViewerApp.swift
│   ├── Views/
│   │   ├── ContentView.swift      # Main editor view
│   │   ├── MermaidWebView.swift   # WebKit-based diagram renderer
│   │   └── SettingsView.swift     # Settings window
│   ├── Resources/
│   │   └── mermaid.min.js         # Bundled Mermaid.js library
│   └── Info.plist
│
├── MermaidQuickLook/        # Quick Look extension
│   ├── PreviewProvider.swift      # QLPreviewProvider implementation
│   ├── Resources/
│   │   ├── mermaid.min.js
│   │   └── icons/                 # Toolbar icons (16x16 PNGs)
│   └── Info.plist
│
├── MermaidThumbnail/        # Thumbnail extension
│   ├── ThumbnailProvider.swift
│   └── Resources/
│
├── Shared/                  # Shared code between targets
│   └── MermaidRenderer.swift      # Common HTML generation
│
├── project.yml              # XcodeGen project configuration
├── Makefile                 # Build automation
└── docs/                    # Documentation
```

## Build System

### Prerequisites

- Xcode 15.0+
- macOS 13.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Makefile Targets

```bash
make generate    # Generate Xcode project from project.yml
make build       # Build the application
make install     # Install to /Applications
make dev         # Full development cycle: generate, build, install, register
make refresh     # Clear all caches and restart services
make status      # Check extension registration status
make clean       # Clean build artifacts
```

### Development Workflow

1. Make code changes
2. Run `make dev` to build and install
3. Test Quick Look with `qlmanage -p /path/to/file.mmd`
4. Check console for errors: `log show --predicate 'subsystem contains "mermaid"' --last 5m`

## Architecture

### Shared MermaidRenderer

The `MermaidRenderer` class in `Shared/MermaidRenderer.swift` provides HTML generation used by all targets:

```swift
class MermaidRenderer {
    init(bundle: Bundle)  // Load resources from specified bundle

    // Full interactive view with toolbar (Quick Look, Settings preview)
    func generateHTML(code: String, options: MermaidRenderOptions, systemIsDark: Bool) -> String

    // Simplified preview without toolbar
    func generatePreviewHTML(code: String, options: MermaidRenderOptions, systemIsDark: Bool) -> String

    // Editor view with live-update JavaScript function
    func generateEditorHTML(code: String, options: MermaidRenderOptions, systemIsDark: Bool, zoomLevel: Double) -> String
}
```

### MermaidRenderOptions

```swift
struct MermaidRenderOptions {
    var theme: String           // "default", "dark", "forest", "neutral", "base"
    var darkModeSetting: String // "system", "light", "dark"
    var sizing: String          // "fit", "expandVertical", "expandHorizontal", "original"
    var showToolbar: Bool
    var showDebug: Bool
    var backgroundMode: String  // "transparent", "opaque"
    var backgroundColor: String // Hex color e.g. "#f5f5f5"
    var mouseMode: String       // "pan", "select"
    var debugLabel: String
}
```

### Settings Storage

Settings are shared between app and extension using App Groups:

```swift
UserDefaults(suiteName: "group.com.roundrect.mermaidviewer")
```

Keys:
- `ql.theme` - Diagram theme
- `ql.darkMode` - Dark mode setting
- `ql.sizing` - Diagram sizing
- `ql.mouseMode` - Default mouse mode
- `ql.backgroundMode` - Background mode
- `ql.backgroundColor` - Background color (hex)
- `ql.showDebug` - Show debug overlay

## Quick Look Extension

### PreviewProvider

The extension implements `QLPreviewProvider` and returns HTML content:

```swift
class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        // Read file, generate HTML, return as .html content type
    }
}
```

### Supported UTIs

Configured in `Info.plist`:
- `com.mermaid.mmd`
- `com.mermaid.mermaid`
- `net.daringfireball.markdown`

## Icons

Toolbar icons are 16x16 PNGs with transparency, using classic Mac cursor styling:
- `icon-hand.png` - Pan mode cursor
- `icon-arrow.png` - Select mode cursor
- `icon-zoom-in.png`, `icon-zoom-out.png`, `icon-zoom-reset.png`
- `icon-checker.png` - Background toggle

High-resolution source files (128x128) are in `icons/source/` for editing.

## Code Signing

The project uses automatic signing with development team `KJ8QMLWB97`. App Groups entitlement requires valid code signing.

### Entitlements

**MermaidViewer.entitlements:**
- `com.apple.security.app-sandbox` = true
- `com.apple.security.application-groups` = ["group.com.roundrect.mermaidviewer"]

**MermaidQuickLook.entitlements:**
- `com.apple.security.app-sandbox` = true
- `com.apple.security.application-groups` = ["group.com.roundrect.mermaidviewer"]

## Troubleshooting

### Extension not loading

```bash
# Check registration
pluginkit -m -v | grep mermaid

# Force re-register
pluginkit -e use -i com.roundrect.mermaidviewer.quicklook
pluginkit -a /Applications/MermaidViewer.app/Contents/PlugIns/MermaidQuickLook.appex
```

### Clear caches

```bash
make refresh
# Or manually:
qlmanage -r && qlmanage -r cache
killall QuickLookUIService quicklookd
killall Finder
```

### Debug Quick Look

```bash
# Test preview generation
qlmanage -p /path/to/file.mmd

# View extension logs
log show --predicate 'subsystem contains "quicklook"' --last 5m
```

## Testing

### Manual Testing

1. Create test file: `echo "flowchart TD\n    A-->B" > /tmp/test.mmd`
2. Run `qlmanage -p /tmp/test.mmd`
3. Verify toolbar appears on mouse interaction
4. Test zoom with scroll wheel
5. Test pan with click-drag

### Build Verification

```bash
make status  # Verify extension registration
```
