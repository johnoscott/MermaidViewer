# MermaidViewer Quick Look Extension - Lessons Learned

## Project Overview
macOS Quick Look extension for previewing Mermaid diagram files (.mmd, .mermaid) directly in Finder.

---

## What Works

### Quick Look Preview
- Renders Mermaid diagrams using bundled mermaid.js (no CDN dependency)
- Supports .mmd, .mermaid, and extracts mermaid blocks from .md files
- Dark/light mode support based on system appearance

### Settings UI
- Theme selection (Default, Dark, Forest, Neutral, Base)
- Background mode (Match System, Always Light, Always Dark)
- Sizing options (Fit to Window, Expand Vertically/Horizontally, Original Size)
- Live preview in the Settings window shows immediate effect of changes

### Build Automation
- `make dev` - Quick rebuild and install for development
- `make refresh` - Clear all caches and restart services
- `make status` - Check extension registration status
- `make reinstall` - Full clean reinstall
- `make test` - Test Quick Look preview

---

## Critical Findings

### 1. Quick Look Extensions REQUIRE Sandbox
- **Disabling sandbox (`ENABLE_APP_SANDBOX: false`) breaks Quick Look entirely**
- The extension simply won't render previews without sandbox enabled
- This is a macOS requirement, not optional

### 2. Sandboxed Extensions Cannot Read External Files
- Cannot read from `/tmp` or `/private/tmp`
- Cannot read from `~/Library/Preferences/`
- Cannot read from arbitrary file paths
- Can ONLY read: the file being previewed, and their own bundle resources

### 3. Temporary Exception Entitlements Don't Work
- Tried: `com.apple.security.temporary-exception.files.absolute-path.read-only`
- Result: Still cannot read from /tmp
- Quick Look extensions have stricter sandbox than regular apps

### 4. UserDefaults Suite Names Don't Work Without App Groups
- `UserDefaults(suiteName: "com.mermaid.viewer.shared")` fails silently
- Extension reads nil/defaults instead of actual values
- App Groups are the ONLY way to share UserDefaults between app and extension

### 5. App Groups Require Paid Developer Account
- App Groups need code signing with a valid Team ID
- Requires Apple Developer Program membership ($99/year)
- Cannot work around this for local development

### Conclusion: Settings Sharing Requires App Groups
Without proper code signing with App Groups, there is **NO workaround** for sharing settings between the main app and the Quick Look extension.

**With App Groups configured correctly, settings sharing WORKS!**

---

## UTI Document Icons

### What We Tried
- Created custom document-shaped icon with flowchart graphic
- Set `UTTypeIconFile` in Info.plist UTI declaration
- Cleared icon cache, restarted Finder

### What Happened
- Icon appears as a **small badge** in the corner of a generic document icon
- Does NOT replace the full document icon
- This is how macOS handles UTI icons - they're overlays, not replacements

### Solution for Full Custom Icons
- Use the **Thumbnail Extension** to render actual diagram previews
- This would show the real diagram content as the file icon
- More complex to implement (requires headless WebKit rendering)

---

## Technical Reference

### Extension Registration
```bash
# Check if extension is registered
pluginkit -m -v | grep mermaid

# Force re-register app with Launch Services
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R /Applications/MermaidViewer.app
```

### Cache Clearing
```bash
# Reset Quick Look
qlmanage -r && qlmanage -r cache

# Kill Quick Look services
killall -9 QuickLookUIService quicklookd

# Clear icon cache (requires sudo)
sudo rm -rf /Library/Caches/com.apple.iconservices.store

# Restart Finder
killall Finder
```

### Required Build Settings
```yaml
# In project.yml for Quick Look extension
settings:
  ENABLE_APP_SANDBOX: true          # REQUIRED - cannot be false
  ENABLE_HARDENED_RUNTIME: true     # Required for extension discovery
  CODE_SIGN_ENTITLEMENTS: MermaidQuickLook/MermaidQuickLook.entitlements
```

### Required Entitlements
```xml
<!-- MermaidQuickLook.entitlements -->
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>  <!-- MUST be true -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
```

---

## Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| Quick Look Preview | ✅ Working | Renders Mermaid diagrams |
| Settings UI | ✅ Working | Live preview + Apply to Finder |
| Theme Selection | ✅ Working | Syncs to Finder via App Groups |
| Dark Mode | ✅ Working | Syncs to Finder via App Groups |
| Document Icons | Partial | Shows as small badge, not full icon |
| Thumbnails | Placeholder | Shows flowchart icon, not actual diagram |

---

## What Finally Worked (App Groups Setup)

1. **Apple Developer Account** - Required for App Groups
2. **Create App Group**: `group.com.roundrect.mermaidviewer`
3. **Create App IDs** with App Groups capability:
   - `com.roundrect.mermaidviewer`
   - `com.roundrect.mermaidviewer.quicklook`
   - `com.roundrect.mermaidviewer.thumbnail`
4. **Set DEVELOPMENT_TEAM** in project.yml
5. **Add `-allowProvisioningUpdates`** to xcodebuild
6. **Register device** via Xcode (automatic on first build)

---

## Future Improvements

1. **Thumbnail Extension Enhancement**
   - Render actual Mermaid diagrams as file thumbnails
   - Would provide full custom document icons

2. **App Store Distribution**
   - All sandbox restrictions already in place
   - App Groups configured and working
