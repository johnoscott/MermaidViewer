# MermaidViewer

A macOS Quick Look extension for previewing Mermaid diagram files (.mmd, .mermaid) directly in Finder.

## Features

- **Quick Look Preview**: Press Space on any .mmd or .mermaid file in Finder
- **Theme Selection**: Default, Dark, Forest, Neutral, Base
- **Dark Mode Support**: Match system, Always Light, Always Dark
- **Sizing Options**: Fit to Window, Expand Vertically/Horizontally, Original Size
- **Markdown Support**: Extracts mermaid blocks from .md files
- **Bundled mermaid.js**: No internet connection required

## Setup (Apple Developer Account Required)

### 1. Create App Group in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list/applicationGroup)
2. Click **+** to create a new App Group
3. Enter identifier: `group.com.roundrect.mermaidviewer`
4. Click **Continue** and **Register**

### 2. Create/Update App IDs

Create or update these App IDs with the App Group capability:

- `com.roundrect.mermaidviewer` (main app)
- `com.roundrect.mermaidviewer.quicklook` (Quick Look extension)
- `com.roundrect.mermaidviewer.thumbnail` (Thumbnail extension)

For each App ID:
1. Enable **App Groups** capability
2. Select `group.com.roundrect.mermaidviewer`

### 3. Configure Team ID

Edit `project.yml` and set your Team ID:

```yaml
settings:
  DEVELOPMENT_TEAM: "YOUR_TEAM_ID"  # e.g., "ABCD1234EF"
```

Find your Team ID at: https://developer.apple.com/account/#/membership

### 4. Build and Install

```bash
# Generate Xcode project and build
make

# Or for development
make dev

# Check extension status
make status
```

## Usage

1. Open the MermaidViewer app to configure settings
2. Click **Apply to Finder** to restart Quick Look with new settings
3. In Finder, select any .mmd file and press **Space** to preview

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make` | Build, install, and register (default) |
| `make dev` | Quick rebuild and install |
| `make clean` | Clean build artifacts |
| `make status` | Check extension registration |
| `make refresh` | Clear caches and restart services |
| `make test` | Test Quick Look preview |

## Project Structure

```
MermaidQuickLook/
├── MermaidViewer/          # Main app
│   ├── Views/
│   │   ├── ContentView.swift
│   │   └── SettingsView.swift
│   └── Resources/
│       └── mermaid.min.js
├── MermaidQuickLook/       # Quick Look extension
│   └── PreviewProvider.swift
├── MermaidThumbnail/       # Thumbnail extension
│   └── ThumbnailProvider.swift
├── project.yml             # xcodegen configuration
└── Makefile               # Build automation
```

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Apple Developer Account (for App Groups)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## License

MIT
