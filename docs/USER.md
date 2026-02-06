# Mermaid Viewer - User Guide

## Overview

Mermaid Viewer is a macOS application that provides Quick Look previews for Mermaid diagram files. Press Space on any `.mmd` or `.mermaid` file in Finder to instantly preview your diagrams.

## Installation

1. Download `MermaidViewer.app`
2. Move it to your Applications folder
3. Launch the app once to register the Quick Look extension
4. The app must remain installed for Quick Look to work

## Supported File Types

- `.mmd` - Mermaid diagram files
- `.mermaid` - Mermaid diagram files
- `.md` / `.markdown` - Markdown files with mermaid code blocks

## Quick Look Preview

### Basic Usage

1. Select a Mermaid file in Finder
2. Press **Space** to open Quick Look
3. The diagram renders automatically

### Interactive Controls

When viewing a diagram in Quick Look, a toolbar appears when you interact:

| Control | Action |
|---------|--------|
| 🖐 Hand | Pan mode - click and drag to move the diagram |
| ➤ Arrow | Select mode - normal cursor for text selection |
| ➖ / ➕ | Zoom out / Zoom in |
| 100% | Current zoom level |
| ⌂ | Reset view to original position and zoom |
| ▦ | Toggle transparent/opaque background |
| 🎨 | Color picker for background color |

### Mouse Controls

- **Scroll wheel**: Zoom in/out (centered on cursor)
- **Click + drag** (in Pan mode): Move the diagram around
- **Double-click**: (in Select mode) Select text

## Settings

Open MermaidViewer.app and go to **Settings** (⌘,) to configure:

### Quick Look Tab

- **Theme**: Choose diagram style (Default, Dark, Forest, Neutral, Base)
- **Appearance**: System/Light/Dark mode
- **Sizing**: How diagrams fit in the preview window
- **Mouse**: Default interaction mode (Pan or Select)
- **Background**: Transparent or solid color
- **Developer**: Show debug information

Click **Apply to Finder** after changing settings to refresh Quick Look.

### Thumbnails Tab

- Enable/disable thumbnail generation for Finder
- Choose between rendered diagram or document icon style

## Main Application

The app also includes a full Mermaid editor:

1. Open MermaidViewer.app
2. Type or paste Mermaid code in the left panel
3. See live preview in the right panel
4. Load files via **Load File...** button or drag & drop

### Editor Controls

- **Theme**: Change diagram theme
- **Dark**: Toggle dark mode
- **Zoom**: Adjust preview zoom level

## Troubleshooting

### Quick Look not working

1. Ensure MermaidViewer.app is in /Applications
2. Open the app's Settings and click **Apply to Finder**
3. Try restarting Finder (Option-Right-click Finder icon → Relaunch)

### Preview shows old version

Quick Look caches previews. To refresh:
1. Open MermaidViewer Settings
2. Click **Apply to Finder**

### Diagram not rendering

- Check your Mermaid syntax is valid
- Enable **Debug Info** in Settings to see error details
- Ensure the file has a supported extension

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Space | Open Quick Look (in Finder) |
| ⌘, | Open Settings (in app) |
| ⌘Q | Quit application |
