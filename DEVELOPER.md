# Developer Guide

## Prerequisites

- macOS 13.0+
- Xcode 15.0+
- Apple Developer Program membership ($99/year — required for App Groups)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Apple Developer Portal Setup

Before building, you need to configure App Groups in your Apple Developer account. See [SETUP.md](SETUP.md) for the step-by-step walkthrough.

Summary of identifiers:

| Component | Bundle ID |
|-----------|-----------|
| Main App | `com.roundrect.mermaidviewer` |
| Quick Look | `com.roundrect.mermaidviewer.quicklook` |
| Thumbnail | `com.roundrect.mermaidviewer.thumbnail` |
| App Group | `group.com.roundrect.mermaidviewer` |

Set your Team ID in `project.yml` under `DEVELOPMENT_TEAM`.

## Build Commands

```bash
make dev              # Primary dev workflow: generate, build, install, register, restart Quick Look
make build            # Build Debug configuration only
make release          # Build Release configuration
make clean            # Clean build + remove generated .xcodeproj
make deep-clean       # Clean + remove DerivedData
make refresh          # Clear all caches + restart Quick Look + restart Finder
make status           # Check if extensions are registered with pluginkit
make test             # Test Quick Look preview with sample .mmd file
make test-thumbnail   # Test thumbnail generation
make reinstall        # Full clean rebuild and install
```

## Development Workflow

1. Make code changes
2. Run `make dev` to build and install
3. Test with `qlmanage -p /path/to/file.mmd`
4. Check logs: `log show --predicate 'subsystem contains "quicklook"' --last 5m`

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
│   │   └── mermaid.min.js
│   └── Info.plist
├── MermaidQuickLook/        # Quick Look extension
│   ├── PreviewProvider.swift
│   ├── Resources/
│   │   ├── mermaid.min.js
│   │   └── icons/                 # Toolbar icons (16x16 PNGs)
│   └── Info.plist
├── MermaidThumbnail/        # Thumbnail extension
│   ├── ThumbnailProvider.swift
│   └── Resources/
├── Shared/                  # Shared code between targets
│   └── MermaidRenderer.swift
├── project.yml              # XcodeGen project configuration
└── Makefile
```

## Architecture

### Three Targets, One Renderer

All HTML/CSS/JS generation lives in `Shared/MermaidRenderer.swift`. Each target bundles its own copy of `mermaid.min.js` (no CDN). The renderer takes a `Bundle` parameter so each target loads resources from its own bundle.

Three HTML generation modes:
- `generateHTML()` — Full interactive view with toolbar/zoom/pan (Quick Look, Settings preview)
- `generateEditorHTML()` — Live-update view with `updateDiagram()` JS callback (main app editor)
- `generatePreviewHTML()` — Simplified static preview

### Settings Sharing

Settings are shared via App Groups using `UserDefaults(suiteName: "group.com.roundrect.mermaidviewer")`. Keys are prefixed `ql.` (e.g., `ql.theme`, `ql.darkMode`, `ql.sizing`). The main app writes via `@AppStorage`, the Quick Look extension reads via shared `UserDefaults`.

### Adding a New Setting

1. Add `@AppStorage("ql.newSetting", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))` in `SettingsView.swift`
2. Add property to `MermaidRenderOptions` in `MermaidRenderer.swift`
3. Read in `PreviewProvider.swift` via `Self.sharedDefaults?.string(forKey:)`
4. Wire up UI control and `.onChange` handler in SettingsView

## Code Signing

The project uses automatic signing with team `KJ8QMLWB97`. App Groups require valid code signing — Quick Look extensions **must** have sandbox enabled or previews silently fail.

### Entitlements

All three targets have:
- `com.apple.security.app-sandbox` = true
- `com.apple.security.application-groups` = `["group.com.roundrect.mermaidviewer"]`

### CI/CD

The GitHub Actions workflow (`.github/workflows/release.yml`) handles signing, notarization, and DMG packaging. See [the workflow file](.github/workflows/release.yml) header comments for secrets setup.

## Toolbar Icons

16x16 PNGs with transparency in `MermaidQuickLook/Resources/icons/`. 128x128 source files in `icons/source/`. Icon names use `icon-` prefix. Add new icons to the `iconNames` array in `MermaidRenderer.init()`.

## Debugging

```bash
# Test preview
qlmanage -p /tmp/test.mmd

# Check registration
pluginkit -m -v | grep mermaid

# Force re-register
pluginkit -e use -i com.roundrect.mermaidviewer.quicklook

# View logs
log show --predicate 'subsystem contains "quicklook"' --last 5m

# Nuclear option
make refresh
```

### Critical Constraints

- Quick Look extensions **must** have sandbox enabled — disabling it silently breaks previews
- Sandboxed extensions can only read the file being previewed and their own bundle resources
- `-allowProvisioningUpdates` must be passed to xcodebuild for automatic signing with App Groups
- Extended attributes on icon PNGs can break code signing — fix with `xattr -cr MermaidQuickLook/Resources/icons/`
