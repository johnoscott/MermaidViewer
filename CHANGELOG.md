# Changelog

## [1.2.1] - 2026-02-09

### Fixed
- Quick Look and Thumbnail extensions now register correctly in release builds installed via Homebrew/DMG
- Added `com.apple.application-identifier` and `com.apple.developer.team-identifier` entitlements to all targets (required for pluginkit registration without provisioning profiles)

## [1.2.0] - 2026-02-08

### Added
- **Multi-document support** — each file opens in its own tab/window with independent state
- **Window titles** — windows show humanised file names (e.g. "my-diagram.mmd" becomes "My Diagram")
- **Configurable keyboard shortcuts** in Settings > Shortcuts tab
  - Toggle Editor: Cmd+1 (default)
  - Next Tab: Ctrl+Tab (default)
  - Previous Tab: Shift+Ctrl+Tab (default)
- **Save support** — edited diagrams can be saved back to disk (Cmd+S)

### Fixed
- WebView no longer steals keyboard focus from tabs and text editor
- Clicking a document tab now correctly activates that document

### Changed
- Switched from singleton state to SwiftUI `DocumentGroup` architecture
- Removed custom `AppDelegate` — file opening handled natively by `DocumentGroup`

## [1.1.0] - 2026-02-07

### Added
- Editor panel hidden by default with sidebar toggle button in toolbar
- Dynamic minimum window width (400px without editor, 800px with)

### Changed
- CI release workflow automatically updates Homebrew cask

## [1.0.0] - 2026-02-07

- Initial release
