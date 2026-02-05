# MermaidViewer Setup Guide

This guide walks you through configuring your Apple Developer account for App Groups, which enables settings sharing between the main app and Quick Look extension.

## Prerequisites

- Apple Developer Program membership ($99/year)
- Xcode 15.0+
- xcodegen (`brew install xcodegen`)

---

## Step 1: Create App Group

1. Go to [Apple Developer Portal - App Groups](https://developer.apple.com/account/resources/identifiers/list/applicationGroup)
2. Click the **+** button to create a new identifier
3. Select **App Groups** and click **Continue**
4. Enter the following:
   - **Description**: MermaidViewer Shared
   - **Identifier**: `group.com.roundrect.mermaidviewer`
5. Click **Continue** and then **Register**

---

## Step 2: Create App IDs

You need to create three App IDs. For each one:

### 2a. Main App ID

1. Go to [App IDs](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** → Select **App IDs** → **App**
3. Enter:
   - **Description**: MermaidViewer
   - **Bundle ID**: Explicit → `com.roundrect.mermaidviewer`
4. Under **Capabilities**, enable **App Groups**
5. Click **Continue** and **Register**
6. After creation, click on the App ID → **Configure** App Groups
7. Select `group.com.roundrect.mermaidviewer`
8. Click **Save**

### 2b. Quick Look Extension ID

1. Click **+** → Select **App IDs** → **App**
2. Enter:
   - **Description**: MermaidViewer Quick Look
   - **Bundle ID**: Explicit → `com.roundrect.mermaidviewer.quicklook`
3. Enable **App Groups** capability
4. Click **Continue** and **Register**
5. Configure App Groups → Select `group.com.roundrect.mermaidviewer`

### 2c. Thumbnail Extension ID

1. Click **+** → Select **App IDs** → **App**
2. Enter:
   - **Description**: MermaidViewer Thumbnail
   - **Bundle ID**: Explicit → `com.roundrect.mermaidviewer.thumbnail`
3. Enable **App Groups** capability
4. Click **Continue** and **Register**
5. Configure App Groups → Select `group.com.roundrect.mermaidviewer`

---

## Step 3: Find Your Team ID

1. Go to [Membership Details](https://developer.apple.com/account/#/membership)
2. Find your **Team ID** (a 10-character alphanumeric string like `ABCD1234EF`)
3. Copy this value

---

## Step 4: Configure project.yml

Edit `project.yml` and add your Team ID to each target:

```yaml
settings:
  SWIFT_VERSION: "5.9"
  MARKETING_VERSION: "1.0.0"
  CURRENT_PROJECT_VERSION: "1"
  ENABLE_HARDENED_RUNTIME: true
  DEVELOPMENT_TEAM: "YOUR_TEAM_ID"  # ← Add this line with your Team ID
```

Replace `YOUR_TEAM_ID` with your actual Team ID from Step 3.

---

## Step 5: Build and Install

```bash
# Clean any previous builds
make clean

# Generate Xcode project and build
make

# Or just rebuild for development
make dev
```

---

## Step 6: Verify Installation

```bash
# Check if extensions are registered
make status
```

You should see output like:
```
com.roundrect.mermaidviewer.quicklook(1.0) ...
com.roundrect.mermaidviewer.thumbnail(1.0) ...
```

---

## Testing Settings Sharing

1. Open **MermaidViewer.app** from `/Applications`
2. Change settings (e.g., select **Forest** theme, **Always Dark**)
3. Click **Apply to Finder**
4. In Finder, select a `.mmd` file and press **Space**
5. The Quick Look preview should now use your selected theme

---

## Troubleshooting

### Quick Look not working
```bash
make refresh   # Clear caches and restart services
make status    # Check extension registration
```

### Settings not applying
- Make sure you clicked **Apply to Finder** in the app
- Verify App Groups are configured for all three App IDs
- Check that the Team ID is set in project.yml

### Code signing errors
- Ensure all App IDs exist in your developer account
- Verify App Groups capability is enabled on all App IDs
- Check that your Team ID is correct

---

## Summary of Identifiers

| Component | Bundle ID | App Group |
|-----------|-----------|-----------|
| Main App | `com.roundrect.mermaidviewer` | `group.com.roundrect.mermaidviewer` |
| Quick Look | `com.roundrect.mermaidviewer.quicklook` | `group.com.roundrect.mermaidviewer` |
| Thumbnail | `com.roundrect.mermaidviewer.thumbnail` | `group.com.roundrect.mermaidviewer` |
