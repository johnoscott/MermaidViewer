# MermaidViewer Makefile
# Build, install, and manage the MermaidViewer Quick Look extension

SCHEME = MermaidViewer
CONFIG = Debug
BUILD_DIR = $(shell xcodebuild -scheme $(SCHEME) -showBuildSettings 2>/dev/null | grep -m 1 'BUILD_DIR' | awk '{print $$3}')
APP_NAME = MermaidViewer.app
APP_PATH = /Applications/$(APP_NAME)
DERIVED_DATA = ~/Library/Developer/Xcode/DerivedData

.PHONY: all build install uninstall clean generate register unregister \
        clear-cache restart-finder refresh test help open kill register-extension

# Default target
all: build install register

# Generate Xcode project from project.yml
generate:
	@echo "==> Generating Xcode project..."
	xcodegen generate

# Build the project
build: generate
	@echo "==> Building $(SCHEME)..."
	xcodebuild -scheme $(SCHEME) -configuration $(CONFIG) -allowProvisioningUpdates build

# Build release version
release: generate
	@echo "==> Building $(SCHEME) (Release)..."
	xcodebuild -scheme $(SCHEME) -configuration Release -allowProvisioningUpdates build

# Install to /Applications
install:
	@echo "==> Installing to $(APP_PATH)..."
	@if [ -d "$(APP_PATH)" ]; then rm -rf "$(APP_PATH)"; fi
	@BUILD_PATH=$$(xcodebuild -scheme $(SCHEME) -configuration $(CONFIG) -showBuildSettings 2>/dev/null | grep -m 1 'BUILT_PRODUCTS_DIR' | awk '{print $$3}'); \
	cp -R "$$BUILD_PATH/$(APP_NAME)" /Applications/
	@echo "==> Installed successfully"

# Uninstall from /Applications
uninstall:
	@echo "==> Uninstalling $(APP_PATH)..."
	@if [ -d "$(APP_PATH)" ]; then rm -rf "$(APP_PATH)"; fi
	@echo "==> Uninstalled successfully"

# Clean build artifacts
clean:
	@echo "==> Cleaning build..."
	xcodebuild -scheme $(SCHEME) clean 2>/dev/null || true
	@rm -rf MermaidViewer.xcodeproj
	@echo "==> Cleaned"

# Deep clean - remove derived data
deep-clean: clean
	@echo "==> Removing derived data..."
	@rm -rf $(DERIVED_DATA)/MermaidViewer-*
	@echo "==> Deep cleaned"

# Register app with Launch Services
register:
	@echo "==> Registering with Launch Services..."
	/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R "$(APP_PATH)"
	@echo "==> Registered"

# Unregister app from Launch Services
unregister:
	@echo "==> Unregistering from Launch Services..."
	/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -u "$(APP_PATH)" 2>/dev/null || true
	@echo "==> Unregistered"

# Clear icon cache
clear-icon-cache:
	@echo "==> Clearing icon cache..."
	@sudo rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null || true
	@rm -rf ~/Library/Caches/com.apple.iconservices* 2>/dev/null || true
	@echo "==> Icon cache cleared"

# Clear Quick Look cache
clear-ql-cache:
	@echo "==> Clearing Quick Look cache..."
	@qlmanage -r 2>/dev/null || true
	@qlmanage -r cache 2>/dev/null || true
	@echo "==> Quick Look cache cleared"

# Clear all caches
clear-cache: clear-icon-cache clear-ql-cache
	@echo "==> All caches cleared"

# Restart Finder
restart-finder:
	@echo "==> Restarting Finder..."
	@killall Finder 2>/dev/null || true
	@sleep 2
	@echo "==> Finder restarted"

# Restart Quick Look daemon
restart-quicklook:
	@echo "==> Restarting Quick Look daemon..."
	@killall -9 QuickLookUIService 2>/dev/null || true
	@killall -9 quicklookd 2>/dev/null || true
	@echo "==> Quick Look daemon restarted"

# Full refresh - clear caches, restart services
refresh: clear-cache restart-quicklook restart-finder
	@echo "==> System refreshed"

# Check extension status
status:
	@echo "==> Quick Look extension status:"
	@pluginkit -m -v | grep -i mermaid || echo "No Mermaid extensions found"
	@echo ""
	@echo "==> UTI registration:"
	@/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -dump | grep -A 5 "com.mermaid.diagram" | head -10 || echo "UTI not registered"

# Test Quick Look with sample file
test:
	@echo "==> Testing Quick Look preview..."
	@if [ ! -f /tmp/test.mmd ]; then \
		echo "flowchart TD\n    A[Start] --> B{Decision}\n    B -->|Yes| C[End]" > /tmp/test.mmd; \
	fi
	@qlmanage -p /tmp/test.mmd &
	@sleep 3
	@killall qlmanage 2>/dev/null || true
	@echo "==> Test complete"

# Test thumbnail generation
test-thumbnail:
	@echo "==> Testing thumbnail generation..."
	@if [ ! -f /tmp/test.mmd ]; then \
		echo "flowchart TD\n    A[Start] --> B{Decision}\n    B -->|Yes| C[End]" > /tmp/test.mmd; \
	fi
	@qlmanage -t -s 512 -o /tmp /tmp/test.mmd
	@echo "==> Thumbnail saved to /tmp/test.mmd.png"

# Open the app
open:
	@echo "==> Opening MermaidViewer..."
	@open "$(APP_PATH)"

# Kill the app
kill:
	@echo "==> Killing MermaidViewer..."
	@killall MermaidViewer 2>/dev/null || true
	@echo "==> Killed"

# Full reinstall - clean, build, install, register, refresh
reinstall: uninstall deep-clean build install register refresh
	@echo "==> Full reinstall complete"

# Development cycle - quick rebuild and install
dev: build install register-extension restart-quicklook
	@echo "==> Development build installed"

# Force re-register the Quick Look extension
register-extension:
	@echo "==> Registering Quick Look extension..."
	@pluginkit -e use -i com.roundrect.mermaidviewer.quicklook 2>/dev/null || true
	@pluginkit -a /Applications/MermaidViewer.app/Contents/PlugIns/MermaidQuickLook.appex 2>/dev/null || true
	@echo "==> Extension registered"

# Show help
help:
	@echo "MermaidViewer Makefile"
	@echo ""
	@echo "Build targets:"
	@echo "  make              - Build, install, and register (default)"
	@echo "  make generate     - Generate Xcode project from project.yml"
	@echo "  make build        - Build the project (Debug)"
	@echo "  make release      - Build the project (Release)"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make deep-clean   - Clean and remove derived data"
	@echo ""
	@echo "Install targets:"
	@echo "  make install      - Install to /Applications"
	@echo "  make uninstall    - Remove from /Applications"
	@echo "  make reinstall    - Full clean reinstall"
	@echo "  make dev          - Quick rebuild and install for development"
	@echo ""
	@echo "Registration targets:"
	@echo "  make register     - Register with Launch Services"
	@echo "  make unregister   - Unregister from Launch Services"
	@echo "  make status       - Check extension and UTI status"
	@echo ""
	@echo "Cache targets:"
	@echo "  make clear-cache       - Clear all caches"
	@echo "  make clear-icon-cache  - Clear icon cache"
	@echo "  make clear-ql-cache    - Clear Quick Look cache"
	@echo ""
	@echo "Service targets:"
	@echo "  make restart-finder    - Restart Finder"
	@echo "  make restart-quicklook - Restart Quick Look daemon"
	@echo "  make refresh           - Clear caches and restart services"
	@echo ""
	@echo "App targets:"
	@echo "  make open         - Open MermaidViewer app"
	@echo "  make kill         - Kill MermaidViewer app"
	@echo ""
	@echo "Test targets:"
	@echo "  make test         - Test Quick Look preview"
	@echo "  make test-thumbnail - Test thumbnail generation"
