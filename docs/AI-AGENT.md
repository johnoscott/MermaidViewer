# Mermaid Viewer - AI Agent Guide

## Project Overview

MermaidViewer is a macOS Quick Look extension for previewing Mermaid diagram files. It consists of three targets sharing common rendering code.

## Key Files

### Entry Points

| File | Purpose |
|------|---------|
| `MermaidQuickLook/PreviewProvider.swift` | Quick Look extension - renders .mmd files when user presses Space in Finder |
| `MermaidViewer/MermaidViewerApp.swift` | Main app entry point |
| `MermaidViewer/Views/ContentView.swift` | Main editor UI |
| `MermaidViewer/Views/SettingsView.swift` | Settings window UI |

### Shared Code

| File | Purpose |
|------|---------|
| `Shared/MermaidRenderer.swift` | **IMPORTANT**: All HTML generation for Mermaid diagrams. Contains CSS, JavaScript, and toolbar code. |

### Configuration

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen configuration - defines targets, entitlements, resources |
| `Makefile` | Build automation - use `make dev` for development builds |

## Common Tasks

### Adding a new setting

1. Add `@AppStorage` property in `SettingsView.swift`:
   ```swift
   @AppStorage("ql.newSetting", store: UserDefaults(suiteName: "group.com.roundrect.mermaidviewer"))
   private var newSetting: String = "default"
   ```

2. Add property to `MermaidRenderOptions` in `MermaidRenderer.swift`

3. Read setting in `PreviewProvider.swift`:
   ```swift
   private var newSetting: String {
       Self.sharedDefaults?.string(forKey: "ql.newSetting") ?? "default"
   }
   ```

4. Pass to options in `providePreview()` method

5. Add UI control in `SettingsView.quickLookSettingsTab`

6. Add `.onChange(of: newSetting)` to mark settings as needing apply

### Modifying the Quick Look toolbar

Edit `MermaidRenderer.swift`:
- `generateToolbarHTML()` - Add/modify buttons
- `generateToolbarJS()` - Add button click handlers
- `generateCSS()` - Modify toolbar styles

### Adding a new toolbar icon

1. Create 16x16 PNG with transparency in `MermaidQuickLook/Resources/icons/`
2. Add icon name to `iconNames` array in `MermaidRenderer.init()`
3. Reference in `generateToolbarHTML()` as `icons["icon-name"]`

### Changing diagram rendering behavior

All diagram rendering happens in `MermaidRenderer.swift`. The HTML includes:
- Mermaid.js initialization and rendering
- Zoom/pan JavaScript
- Toolbar interaction handlers
- CSS for layout and dark mode

## Build Commands

```bash
make dev      # Full rebuild and install (use this most often)
make refresh  # Clear caches after install
make status   # Check if extension is registered
```

## Architecture Notes

### Why three HTML generators?

1. `generateHTML()` - Full interactive view with toolbar, zoom, pan. Used by Quick Look and Settings preview.

2. `generatePreviewHTML()` - Simplified static preview. Currently unused but available for simpler use cases.

3. `generateEditorHTML()` - Live-update view with `updateDiagram()` JS function. Used by main app editor for real-time code changes.

### Settings flow

```
User changes setting in SettingsView
    ↓
@AppStorage writes to App Group UserDefaults
    ↓
User clicks "Apply to Finder"
    ↓
App runs: qlmanage -r && killall QuickLookUIService
    ↓
Next Quick Look reads fresh settings from UserDefaults
```

### Bundle resources

Each target has its own bundle. Resources must be included in the correct target:
- Main app: `Bundle.main`
- Quick Look: `Bundle(for: PreviewProvider.self)`

The `MermaidRenderer` takes a bundle parameter to load resources correctly.

## Common Issues

### Quick Look not updating

Run `make refresh` or the full command:
```bash
qlmanage -r && qlmanage -r cache && killall QuickLookUIService quicklookd && killall Finder
```

### Code signing errors

Extended attributes can cause signing failures:
```bash
xattr -cr MermaidQuickLook/Resources/icons/
```

### Settings not persisting

App Groups require valid code signing. Check that:
- `DEVELOPMENT_TEAM` is set in project.yml
- Entitlements include the app group
- Both app and extension have matching app group

## Code Style

- Swift 5.9, SwiftUI for UI
- Prefer `@AppStorage` for settings
- HTML generation uses Swift string interpolation
- Icon names use `icon-` prefix
- Settings keys use `ql.` prefix for Quick Look settings

## Testing Changes

1. `make dev` - rebuild and install
2. `qlmanage -p /tmp/test.mmd` - test Quick Look
3. Open app to test main editor and settings
4. Check settings preview updates live
