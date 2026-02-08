# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Summary

MermaidViewer is a macOS Quick Look extension for previewing Mermaid diagram files (.mmd, .mermaid) in Finder. It consists of three targets: the main app (MermaidViewer), a Quick Look extension (MermaidQuickLook), and a Thumbnail extension (MermaidThumbnail). Built with Swift 5.9/SwiftUI, targeting macOS 13.0+.

## Build Commands

```bash
make dev              # Primary dev workflow: generate project, build, install, register extension, restart Quick Look
make build            # Build Debug configuration only
make release          # Build Release configuration
make refresh          # Clear all caches + restart Quick Look + restart Finder
make status           # Check if extensions are registered with pluginkit
make test             # Test Quick Look preview with sample .mmd file
make test-thumbnail   # Test thumbnail generation
make reinstall        # Full clean rebuild and install
make clean            # Clean build + remove generated .xcodeproj
make deep-clean       # Clean + remove DerivedData
```

Requires `xcodegen` (`brew install xcodegen`). The Makefile runs `xcodegen generate` automatically before builds.

## Architecture

### Three Targets, One Renderer

All HTML/CSS/JS generation lives in `Shared/MermaidRenderer.swift` (~860 lines). Each target gets its own copy of `mermaid.min.js` (bundled, no CDN). The renderer takes a `Bundle` parameter so each target loads resources from its own bundle.

Three HTML generation modes:
- `generateHTML()` — Full interactive view with toolbar/zoom/pan (Quick Look extension, Settings preview)
- `generateEditorHTML()` — Live-update view with `updateDiagram()` JS callback (main app editor)
- `generatePreviewHTML()` — Simplified static preview (currently unused)

### Settings Flow

Settings are shared via App Groups (`group.com.roundrect.mermaidviewer`) using `UserDefaults(suiteName:)`. Keys are prefixed `ql.` (e.g., `ql.theme`, `ql.darkMode`, `ql.sizing`). The main app writes via `@AppStorage`, the Quick Look extension reads via shared `UserDefaults`. Changes require "Apply to Finder" which runs `qlmanage -r && killall QuickLookUIService`.

### Adding a New Setting

1. Add `@AppStorage("ql.newSetting", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))` in `SettingsView.swift`
2. Add property to `MermaidRenderOptions` in `MermaidRenderer.swift`
3. Read in `PreviewProvider.swift` via `Self.sharedDefaults?.string(forKey:)`
4. Wire up UI control and `.onChange` handler in `SettingsView`

## Critical Constraints

- **Quick Look extensions MUST have sandbox enabled** — disabling it silently breaks previews entirely
- **Sandboxed extensions can only read**: the file being previewed and their own bundle resources (no /tmp, no ~/Library)
- **App Groups require a paid Apple Developer account** ($99/year) — there is no workaround for sharing settings between app and extension
- **`-allowProvisioningUpdates`** must be passed to xcodebuild for automatic signing with App Groups
- **Extended attributes on icon PNGs** can break code signing — fix with `xattr -cr MermaidQuickLook/Resources/icons/`

## Code Signing & Identifiers

- Team ID: `KJ8QMLWB97` (set in `project.yml`)
- App Group: `group.com.roundrect.mermaidviewer`
- Bundle IDs: `com.roundrect.mermaidviewer`, `.quicklook`, `.thumbnail`

## Toolbar Icons

16x16 PNGs with transparency in `MermaidQuickLook/Resources/icons/`. 128x128 source files in `icons/source/`. Icon names use `icon-` prefix. Add new icons to the `iconNames` array in `MermaidRenderer.init()`.

## Slash Commands

Custom commands for common workflows. Use these in Claude Code with `/<command>`:

| Command | Args | Description |
|---------|------|-------------|
| `/run` | — | Build and launch the app for local testing |
| `/pr` | `[branch-name]` | Create a PR from current changes |
| `/ci` | — | Check latest CI run status |
| `/release` | `<version>` | Tag and release a version (e.g. `/release 1.3.0`) |
| `/merge-and-release` | `<version>` | Merge current PR + release (e.g. `/merge-and-release 1.3.0`) |
| `/homebrew-check` | — | Verify Homebrew cask is in sync with latest release |

### Typical workflow

1. Make changes
2. `/run` — build and test locally
3. `/pr feature/my-change` — create a PR
4. `/merge-and-release 1.3.0` — merge, tag, CI builds + publishes to Homebrew
5. `/homebrew-check` — verify cask updated

## Debugging Quick Look

```bash
qlmanage -p /tmp/test.mmd                                    # Test preview
log show --predicate 'subsystem contains "quicklook"' --last 5m  # View logs
pluginkit -m -v | grep mermaid                               # Check registration
make refresh                                                  # Nuclear option: clear all caches
```
