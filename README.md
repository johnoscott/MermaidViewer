# MermaidViewer

> [!TIP]
> **Enjoying MermaidViewer?** Please [star this repo](https://github.com/johnoscott/MermaidViewer) — it helps us reach the threshold to publish to the main [Homebrew](https://brew.sh) registry. You can still install via Homebrew right now — see [Installation](#installation) below.

A macOS app and Quick Look extension for Mermaid diagram files (.mmd, .mermaid). Preview diagrams directly in Finder with **Space**, edit them live in the built-in editor, and see rendered thumbnails in icon view.

## Installation

### Homebrew

```bash
brew install johnoscott/mermaid-viewer/mermaid-viewer
```

### Manual

1. Download **MermaidViewer.dmg** from the [latest release](https://github.com/johnoscott/MermaidViewer/releases/latest)
2. Open the DMG and drag **MermaidViewer.app** to your Applications folder

Then launch the app once to register the Quick Look extension.

> The app must remain in /Applications for Quick Look to work. No internet connection required — Mermaid.js is bundled.

## Supported File Types

- `.mmd` — Mermaid diagram files
- `.mermaid` — Mermaid diagram files

## Quick Look Preview

Select a Mermaid file in Finder and press **Space**. A toolbar appears when you scroll to zoom or click and drag:

| Control | Action |
|---------|--------|
| Hand | Pan mode — click and drag to move the diagram |
| Arrow | Select mode — normal cursor |
| - / + | Zoom out / Zoom in |
| 100% | Current zoom level |
| Home | Reset view to original position and zoom |
| Grid | Toggle transparent/opaque background |
| Color | Background color picker |

**Mouse controls:** scroll wheel to zoom (centered on cursor), click+drag to pan.

## Finder Thumbnails

Mermaid files show rendered diagram thumbnails in Finder icon view and column view. Thumbnail style is configurable in the app settings.

## Settings

Open MermaidViewer and go to **Settings** (Cmd+,) to configure:

- **Theme** — Default, Dark, Forest, Neutral, Base
- **Appearance** — Match system, Always Light, Always Dark
- **Sizing** — Fit to Window, Expand Vertically/Horizontally, Original Size
- **Mouse Mode** — Default to Pan or Select
- **Background** — Transparent or solid color
- **Debug** — Show diagnostic info overlay

Click **Apply to Finder** after changing settings to refresh Quick Look.

## Mermaid Editor

The app includes a built-in editor:

1. Open MermaidViewer
2. Type or paste Mermaid code in the left panel
3. See a live preview in the right panel
4. Load files via the **Load File...** button or drag and drop

## Troubleshooting

**Quick Look not showing previews:**
1. Make sure MermaidViewer.app is in /Applications
2. Open the app, go to Settings, and click **Apply to Finder**
3. Try relaunching Finder (Option+right-click Finder icon in Dock, then Relaunch)

**Preview shows stale content:**
Quick Look caches previews. Open Settings and click **Apply to Finder** to clear the cache.

**Diagram not rendering:**
- Verify your Mermaid syntax is valid
- Enable **Debug Info** in Settings to see error details
- Check the file has a supported extension (.mmd, .mermaid)

## Requirements

- macOS 13.0 (Ventura) or later

## Like it? Star the repo

If you find MermaidViewer useful, please consider [starring the repo](https://github.com/johnoscott/MermaidViewer) — it helps the project get accepted into the main [Homebrew](https://brew.sh) registry so more people can discover it with a simple `brew install mermaid-viewer`.

## Building from Source

See [DEVELOPER.md](DEVELOPER.md) for build instructions and architecture details.

## License

MIT
