import Foundation
import WebKit

/// Configuration options for Mermaid diagram rendering
struct MermaidRenderOptions {
    var theme: String = "default"
    var darkModeSetting: String = "system"  // "system", "light", "dark"
    var sizing: String = "fit"
    var showToolbar: Bool = true
    var showDebug: Bool = false
    var backgroundMode: String = "transparent"  // "transparent", "opaque"
    var backgroundColor: String = "#f5f5f5"
    var mouseMode: String = "pan"  // "pan", "select"
    var debugLabel: String = ""

    /// Computed dark mode based on setting and system preference
    func isDarkMode(systemIsDark: Bool) -> Bool {
        switch darkModeSetting {
        case "light": return false
        case "dark": return true
        default: return systemIsDark
        }
    }
}

/// Renders Mermaid diagrams to HTML with interactive features
class MermaidRenderer {

    private let mermaidJS: String
    private let icons: [String: String]

    /// Initialize renderer with resources from the specified bundle
    init(bundle: Bundle) {
        // Load mermaid.js
        if let url = bundle.url(forResource: "mermaid.min", withExtension: "js"),
           let js = try? String(contentsOf: url, encoding: .utf8) {
            self.mermaidJS = js
        } else {
            self.mermaidJS = "console.error('mermaid.min.js not found');"
        }

        // Load icons
        var loadedIcons: [String: String] = [:]
        let iconNames = ["icon-hand", "icon-arrow", "icon-zoom-out", "icon-zoom-in", "icon-zoom-reset", "icon-checker"]
        for name in iconNames {
            if let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "icons"),
               let data = try? Data(contentsOf: url) {
                loadedIcons[name] = "data:image/png;base64," + data.base64EncodedString()
            } else {
                loadedIcons[name] = ""
            }
        }
        self.icons = loadedIcons
    }

    /// Generate HTML for rendering a Mermaid diagram
    /// - Parameters:
    ///   - code: The Mermaid diagram code
    ///   - options: Rendering options
    ///   - systemIsDark: Whether the system is currently in dark mode
    /// - Returns: Complete HTML string
    func generateHTML(code: String, options: MermaidRenderOptions, systemIsDark: Bool = false) -> String {
        let escapedCode = code
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let isDark = options.isDarkMode(systemIsDark: systemIsDark)
        let darkModeJS: String
        switch options.darkModeSetting {
        case "light": darkModeJS = "false"
        case "dark": darkModeJS = "true"
        default: darkModeJS = "window.matchMedia('(prefers-color-scheme: dark)').matches"
        }

        let mermaidTheme = options.theme == "default" && isDark ? "dark" : options.theme
        let isOpaqueBg = options.backgroundMode == "opaque"
        let isPanMode = options.mouseMode == "pan"

        let debugDiv = options.showDebug ? """
            <div id="debug">\(options.debugLabel)</div>
            """ : ""

        let toolbarHTML = options.showToolbar ? generateToolbarHTML(options: options) : ""
        let toolbarJS = options.showToolbar ? generateToolbarJS() : ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                \(generateCSS(options: options))
            </style>
            <script>
            \(mermaidJS)
            </script>
        </head>
        <body>
            <div id="container">
                <pre class="mermaid">\(escapedCode)</pre>
            </div>
            \(toolbarHTML)
            \(debugDiv)
            <script>
                const isDark = \(darkModeJS);
                let isOpaque = \(isOpaqueBg);
                let currentBgColor = '\(options.backgroundColor)';
                let isPanMode = \(isPanMode);

                function updateBodyClass() {
                    if (isOpaque) {
                        document.body.className = 'opaque';
                        document.body.style.background = currentBgColor;
                    } else {
                        document.body.className = isDark ? 'dark' : 'light';
                        document.body.style.background = '';
                    }
                }
                updateBodyClass();

                function updateMouseMode() {
                    const container = document.getElementById('container');
                    const panBtn = document.getElementById('mode-pan');
                    const selectBtn = document.getElementById('mode-select');

                    container.classList.remove('pan-mode', 'select-mode');
                    container.classList.add(isPanMode ? 'pan-mode' : 'select-mode');

                    if (panBtn) panBtn.classList.toggle('active', isPanMode);
                    if (selectBtn) selectBtn.classList.toggle('active', !isPanMode);
                }
                updateMouseMode();

                let selectedTheme = '\(mermaidTheme)';

                // Zoom and pan state
                let zoom = 1;
                let panX = 0;
                let panY = 0;
                let isDragging = false;
                let dragStartX = 0;
                let dragStartY = 0;
                let initialScale = 1;

                const container = document.getElementById('container');

                function updateTransform() {
                    const mermaid = document.querySelector('.mermaid');
                    if (mermaid) {
                        mermaid.style.transform = `translate(${panX}px, ${panY}px) scale(${zoom})`;
                    }
                    const zoomLevel = document.getElementById('zoom-level');
                    if (zoomLevel) zoomLevel.textContent = Math.round(zoom * 100) + '%';
                }

                \(toolbarJS)

                function setZoom(newZoom, centerX, centerY) {
                    const oldZoom = zoom;
                    zoom = Math.max(0.1, Math.min(10, newZoom));

                    if (centerX !== undefined && centerY !== undefined) {
                        const rect = container.getBoundingClientRect();
                        const x = centerX - rect.left - rect.width / 2;
                        const y = centerY - rect.top - rect.height / 2;
                        panX = panX - x * (zoom / oldZoom - 1);
                        panY = panY - y * (zoom / oldZoom - 1);
                    }

                    if (typeof showToolbar === 'function') showToolbar();
                    updateTransform();
                }

                // Mouse wheel zoom
                container.addEventListener('wheel', (e) => {
                    e.preventDefault();
                    const delta = e.deltaY > 0 ? 0.9 : 1.1;
                    setZoom(zoom * delta, e.clientX, e.clientY);
                }, { passive: false });

                // Pan with mouse drag (only in pan mode)
                container.addEventListener('mousedown', (e) => {
                    if (e.button !== 0 || !isPanMode) return;
                    isDragging = true;
                    dragStartX = e.clientX - panX;
                    dragStartY = e.clientY - panY;
                    container.classList.add('dragging');
                });

                document.addEventListener('mousemove', (e) => {
                    if (!isDragging) return;
                    panX = e.clientX - dragStartX;
                    panY = e.clientY - dragStartY;
                    if (typeof showToolbar === 'function') showToolbar();
                    updateTransform();
                });

                document.addEventListener('mouseup', () => {
                    isDragging = false;
                    container.classList.remove('dragging');
                });

                mermaid.initialize({
                    startOnLoad: false,
                    theme: selectedTheme,
                    securityLevel: 'loose',
                    flowchart: { useMaxWidth: false },
                    sequence: { useMaxWidth: false },
                    gantt: { useMaxWidth: false },
                    er: { useMaxWidth: false },
                    classDiagram: { useMaxWidth: false }
                });

                mermaid.run().then(() => {
                    const svg = document.querySelector('.mermaid svg');
                    if (!svg) return;

                    let svgW, svgH;
                    const viewBox = svg.getAttribute('viewBox');
                    if (viewBox) {
                        const parts = viewBox.split(' ').map(Number);
                        svgW = parts[2];
                        svgH = parts[3];
                    } else {
                        const bbox = svg.getBBox();
                        svgW = bbox.width;
                        svgH = bbox.height;
                    }

                    const margin = 16;
                    const viewW = window.innerWidth - margin * 2;
                    const viewH = window.innerHeight - margin * 2;

                    const scaleX = viewW / svgW;
                    const scaleY = viewH / svgH;
                    initialScale = Math.min(scaleX, scaleY);

                    const finalW = svgW * initialScale;
                    const finalH = svgH * initialScale;

                    svg.setAttribute('width', finalW);
                    svg.setAttribute('height', finalH);
                    svg.style.width = finalW + 'px';
                    svg.style.height = finalH + 'px';

                    const debug = document.getElementById('debug');
                    if (debug) {
                        debug.textContent += ' | SVG: ' + Math.round(svgW) + 'x' + Math.round(svgH) + ' → ' + Math.round(finalW) + 'x' + Math.round(finalH);
                    }
                }).catch(e => {
                    document.getElementById('container').innerHTML = '<div id="error">Error: ' + e.message + '</div>';
                });
            </script>
        </body>
        </html>
        """
    }

    /// Generate simplified HTML for preview (no toolbar, no interactivity)
    func generatePreviewHTML(code: String, options: MermaidRenderOptions, systemIsDark: Bool = false) -> String {
        let escapedCode = code
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")

        let isDark = options.isDarkMode(systemIsDark: systemIsDark)

        let sizingCSS: String
        switch options.sizing {
        case "expandVertical":
            sizingCSS = "height: 100%; width: auto;"
        case "expandHorizontal":
            sizingCSS = "width: 100%; height: auto;"
        case "original":
            sizingCSS = ""
        default: // fit
            sizingCSS = "max-width: 100%; max-height: 100%;"
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    overflow: auto;
                    background: \(isDark ? "#1e1e1e" : "#f5f5f5");
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    padding: 10px;
                }
                #diagram {
                    background: \(isDark ? "#2d2d2d" : "white");
                    border-radius: 8px;
                    padding: 16px;
                    box-shadow: 0 2px 10px rgba(0, 0, 0, \(isDark ? "0.4" : "0.1"));
                    \(sizingCSS)
                }
                .mermaid svg {
                    \(sizingCSS)
                }
            </style>
            <script>\(mermaidJS)</script>
        </head>
        <body>
            <div id="diagram">
                <div class="mermaid"></div>
            </div>
            <script>
                mermaid.initialize({
                    startOnLoad: false,
                    theme: '\(options.theme)',
                    securityLevel: 'loose'
                });
                (async () => {
                    try {
                        const { svg } = await mermaid.render('preview', `\(escapedCode)`);
                        document.querySelector('.mermaid').innerHTML = svg;
                    } catch (e) {
                        document.querySelector('.mermaid').innerHTML = '<p style="color:red">' + e.message + '</p>';
                    }
                })();
            </script>
        </body>
        </html>
        """
    }

    /// Generate HTML for document editor view with live-update support
    /// This version includes a JavaScript updateDiagram() function for dynamic updates
    func generateEditorHTML(code: String, options: MermaidRenderOptions, systemIsDark: Bool = false, zoomLevel: Double = 1.0) -> String {
        let escapedCode = code
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        let isDark = options.isDarkMode(systemIsDark: systemIsDark)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    transition: background-color 0.3s;
                }
                body.dark { background: #1e1e1e; }
                body.light { background: #f5f5f5; }
                #container {
                    width: 100%;
                    height: 100%;
                    overflow: auto;
                    display: flex;
                    justify-content: center;
                    align-items: flex-start;
                    padding: 20px;
                }
                #container.pan-mode { cursor: grab; }
                #container.pan-mode.dragging { cursor: grabbing; }
                #diagram {
                    transform-origin: center top;
                    transition: transform 0.2s ease;
                    background: white;
                    border-radius: 8px;
                    padding: 20px;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
                }
                body.dark #diagram {
                    background: #2d2d2d;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
                }
                body.dark #diagram.dark-theme {
                    background: #1a1a2e;
                }
                #error {
                    color: #ff6b6b;
                    padding: 20px;
                    font-family: monospace;
                    white-space: pre-wrap;
                }
                .mermaid { font-family: 'trebuchet ms', verdana, arial, sans-serif; }
                #toolbar {
                    position: fixed;
                    top: 12px;
                    right: 12px;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 12px;
                    background: rgba(255,255,255,0.95);
                    border-radius: 6px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
                    z-index: 9999;
                    display: flex;
                    align-items: center;
                    gap: 2px;
                    padding: 4px;
                    opacity: 0;
                    transition: opacity 0.2s ease;
                    pointer-events: none;
                }
                #toolbar.visible { opacity: 1; pointer-events: auto; }
                body.dark #toolbar { background: rgba(50,50,50,0.95); color: #fff; }
                #toolbar button {
                    width: 28px;
                    height: 28px;
                    border: none;
                    background: transparent;
                    cursor: pointer;
                    border-radius: 4px;
                    font-size: 16px;
                    color: inherit;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                #toolbar button img {
                    width: 16px;
                    height: 16px;
                    image-rendering: pixelated;
                    image-rendering: crisp-edges;
                }
                #toolbar button:hover { background: rgba(0,0,0,0.1); }
                #toolbar button.active { background: rgba(0,0,0,0.15); }
                body.dark #toolbar button:hover { background: rgba(255,255,255,0.1); }
                body.dark #toolbar button.active { background: rgba(255,255,255,0.2); }
                #zoom-level {
                    min-width: 44px;
                    text-align: center;
                    font-weight: 500;
                    font-variant-numeric: tabular-nums;
                    font-size: 11px;
                }
                .toolbar-divider {
                    width: 1px;
                    height: 20px;
                    background: rgba(0,0,0,0.15);
                    margin: 0 4px;
                }
                body.dark .toolbar-divider { background: rgba(255,255,255,0.2); }
            </style>
            <script>\(mermaidJS)</script>
        </head>
        <body class="\(isDark ? "dark" : "light")">
            <div id="container" class="pan-mode">
                <div id="diagram">
                    <div class="mermaid"></div>
                </div>
            </div>
            <div id="toolbar">
                <button id="mode-pan" class="active" title="Pan Mode">
                    <img src="\(icons["icon-hand"] ?? "")">
                </button>
                <button id="mode-select" title="Select Mode">
                    <img src="\(icons["icon-arrow"] ?? "")">
                </button>
                <div class="toolbar-divider"></div>
                <button id="zoom-out" title="Zoom Out">
                    <img src="\(icons["icon-zoom-out"] ?? "")">
                </button>
                <span id="zoom-level">100%</span>
                <button id="zoom-in" title="Zoom In">
                    <img src="\(icons["icon-zoom-in"] ?? "")">
                </button>
                <button id="zoom-reset" title="Reset Zoom">
                    <img src="\(icons["icon-zoom-reset"] ?? "")">
                </button>
            </div>
            <script>
                let currentZoom = \(zoomLevel);
                let renderCount = 0;
                let isPanMode = true;
                let isDragging = false;
                let panX = 0, panY = 0;
                let dragStartX = 0, dragStartY = 0;

                const container = document.getElementById('container');
                const diagram = document.getElementById('diagram');
                const toolbar = document.getElementById('toolbar');

                function showToolbar() {
                    toolbar.classList.add('visible');
                }

                function updateZoomDisplay() {
                    document.getElementById('zoom-level').textContent = Math.round(currentZoom * 100) + '%';
                }

                function updateTransform() {
                    diagram.style.transform = `translate(${panX}px, ${panY}px) scale(${currentZoom})`;
                    updateZoomDisplay();
                }

                function initMermaid(theme) {
                    mermaid.initialize({
                        startOnLoad: false,
                        theme: theme,
                        securityLevel: 'loose',
                        flowchart: { useMaxWidth: false, htmlLabels: true },
                        sequence: { useMaxWidth: false },
                        gantt: { useMaxWidth: false }
                    });
                }

                initMermaid('\(options.theme)');

                async function updateDiagram(code, theme, darkMode, zoom) {
                    document.body.className = darkMode ? 'dark' : 'light';
                    currentZoom = zoom;
                    updateTransform();

                    if (theme === 'dark') {
                        diagram.classList.add('dark-theme');
                    } else {
                        diagram.classList.remove('dark-theme');
                    }

                    if (!code || code.trim() === '') {
                        diagram.innerHTML = '<p style="color: #888;">Enter Mermaid code to see diagram</p>';
                        return;
                    }

                    try {
                        initMermaid(theme);
                        renderCount++;
                        const { svg } = await mermaid.render('mermaid-' + renderCount, code);
                        diagram.innerHTML = svg;
                    } catch (e) {
                        diagram.innerHTML = '<div id="error">Error: ' + e.message + '</div>';
                    }
                }

                // Mouse wheel zoom
                container.addEventListener('wheel', (e) => {
                    e.preventDefault();
                    const delta = e.deltaY > 0 ? 0.9 : 1.1;
                    currentZoom = Math.max(0.1, Math.min(10, currentZoom * delta));
                    showToolbar();
                    updateTransform();
                }, { passive: false });

                // Pan with drag
                container.addEventListener('mousedown', (e) => {
                    if (e.button !== 0 || !isPanMode) return;
                    isDragging = true;
                    dragStartX = e.clientX - panX;
                    dragStartY = e.clientY - panY;
                    container.classList.add('dragging');
                });

                document.addEventListener('mousemove', (e) => {
                    if (!isDragging) return;
                    panX = e.clientX - dragStartX;
                    panY = e.clientY - dragStartY;
                    showToolbar();
                    updateTransform();
                });

                document.addEventListener('mouseup', () => {
                    isDragging = false;
                    container.classList.remove('dragging');
                });

                // Toolbar buttons
                document.getElementById('mode-pan').addEventListener('click', () => {
                    isPanMode = true;
                    container.classList.add('pan-mode');
                    document.getElementById('mode-pan').classList.add('active');
                    document.getElementById('mode-select').classList.remove('active');
                    showToolbar();
                });

                document.getElementById('mode-select').addEventListener('click', () => {
                    isPanMode = false;
                    container.classList.remove('pan-mode');
                    document.getElementById('mode-pan').classList.remove('active');
                    document.getElementById('mode-select').classList.add('active');
                    showToolbar();
                });

                document.getElementById('zoom-in').addEventListener('click', () => {
                    currentZoom = Math.min(10, currentZoom * 1.25);
                    showToolbar();
                    updateTransform();
                });

                document.getElementById('zoom-out').addEventListener('click', () => {
                    currentZoom = Math.max(0.1, currentZoom * 0.8);
                    showToolbar();
                    updateTransform();
                });

                document.getElementById('zoom-reset').addEventListener('click', () => {
                    currentZoom = 1;
                    panX = 0;
                    panY = 0;
                    showToolbar();
                    updateTransform();
                });

                // Initial render
                updateDiagram(`\(escapedCode)`, '\(options.theme)', \(isDark), \(zoomLevel));
            </script>
        </body>
        </html>
        """
    }

    // MARK: - Private Helpers

    private func generateCSS(options: MermaidRenderOptions) -> String {
        return """
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                }
                body.light { background: #f5f5f5; }
                body.dark { background: #1e1e1e; }
                body.opaque { background: \(options.backgroundColor); }
                #container {
                    width: 100%;
                    height: 100%;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                }
                #container.pan-mode {
                    cursor: grab;
                }
                #container.pan-mode.dragging {
                    cursor: grabbing;
                }
                #container.select-mode {
                    cursor: default;
                }
                .mermaid {
                    font-family: 'trebuchet ms', verdana, arial, sans-serif;
                    transform-origin: center center;
                    transition: none;
                }
                .mermaid svg {
                    display: block;
                }
                #error {
                    color: #ff6b6b;
                    font-family: ui-monospace, monospace;
                    white-space: pre-wrap;
                    padding: 20px;
                    background: rgba(255,107,107,0.1);
                    border-radius: 8px;
                    max-width: 80%;
                }
                #toolbar {
                    position: fixed;
                    top: 12px;
                    right: 12px;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 12px;
                    background: rgba(255,255,255,0.95);
                    border-radius: 6px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
                    z-index: 9999;
                    display: flex;
                    align-items: center;
                    gap: 2px;
                    padding: 4px;
                    opacity: 0;
                    transition: opacity 0.2s ease;
                    pointer-events: none;
                }
                #toolbar.visible {
                    opacity: 1;
                    pointer-events: auto;
                }
                body.dark #toolbar {
                    background: rgba(50,50,50,0.95);
                    color: #fff;
                }
                #toolbar button {
                    width: 28px;
                    height: 28px;
                    border: none;
                    background: transparent;
                    cursor: pointer;
                    border-radius: 4px;
                    font-size: 16px;
                    color: inherit;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                #toolbar button img {
                    width: 16px;
                    height: 16px;
                    image-rendering: pixelated;
                    image-rendering: crisp-edges;
                }
                #toolbar button:hover {
                    background: rgba(0,0,0,0.1);
                }
                #toolbar button.active {
                    background: rgba(0,0,0,0.15);
                }
                body.dark #toolbar button:hover {
                    background: rgba(255,255,255,0.1);
                }
                body.dark #toolbar button.active {
                    background: rgba(255,255,255,0.2);
                }
                #zoom-level {
                    min-width: 44px;
                    text-align: center;
                    font-weight: 500;
                    font-variant-numeric: tabular-nums;
                    font-size: 11px;
                }
                .toolbar-divider {
                    width: 1px;
                    height: 20px;
                    background: rgba(0,0,0,0.15);
                    margin: 0 4px;
                }
                body.dark .toolbar-divider {
                    background: rgba(255,255,255,0.2);
                }
                #bg-color {
                    width: 24px;
                    height: 24px;
                    border: 2px solid rgba(0,0,0,0.2);
                    border-radius: 4px;
                    cursor: pointer;
                    padding: 0;
                    background: transparent;
                }
                #bg-color::-webkit-color-swatch-wrapper {
                    padding: 0;
                }
                #bg-color::-webkit-color-swatch {
                    border: none;
                    border-radius: 2px;
                }
                #debug {
                    position: fixed;
                    bottom: 8px;
                    left: 8px;
                    font-family: ui-monospace, monospace;
                    font-size: 10px;
                    color: rgba(0,0,0,0.5);
                    background: rgba(255,255,255,0.8);
                    padding: 4px 8px;
                    border-radius: 4px;
                    z-index: 9999;
                }
                body.dark #debug {
                    color: rgba(255,255,255,0.5);
                    background: rgba(0,0,0,0.5);
                }
        """
    }

    private func generateToolbarHTML(options: MermaidRenderOptions) -> String {
        return """
            <div id="toolbar">
                <button id="mode-pan" title="Pan Mode (Hand)">
                    <img src="\(icons["icon-hand"] ?? "")">
                </button>
                <button id="mode-select" title="Select Mode (Arrow)">
                    <img src="\(icons["icon-arrow"] ?? "")">
                </button>
                <div class="toolbar-divider"></div>
                <button id="zoom-out" title="Zoom Out">
                    <img src="\(icons["icon-zoom-out"] ?? "")">
                </button>
                <span id="zoom-level">100%</span>
                <button id="zoom-in" title="Zoom In">
                    <img src="\(icons["icon-zoom-in"] ?? "")">
                </button>
                <button id="zoom-reset" title="Reset View">
                    <img src="\(icons["icon-zoom-reset"] ?? "")">
                </button>
                <div class="toolbar-divider"></div>
                <button id="bg-toggle" title="Toggle Background">
                    <img src="\(icons["icon-checker"] ?? "")">
                </button>
                <input type="color" id="bg-color" value="\(options.backgroundColor)" title="Background Color">
            </div>
        """
    }

    private func generateToolbarJS() -> String {
        return """
                const toolbar = document.getElementById('toolbar');
                const zoomLevel = document.getElementById('zoom-level');
                const bgToggle = document.getElementById('bg-toggle');
                const bgColorPicker = document.getElementById('bg-color');

                function showToolbar() {
                    toolbar.classList.add('visible');
                }

                bgToggle.addEventListener('click', () => {
                    isOpaque = !isOpaque;
                    updateBodyClass();
                    showToolbar();
                });

                bgColorPicker.addEventListener('input', (e) => {
                    currentBgColor = e.target.value;
                    if (!isOpaque) {
                        isOpaque = true;
                    }
                    updateBodyClass();
                    showToolbar();
                });

                document.getElementById('mode-pan').addEventListener('click', () => {
                    isPanMode = true;
                    updateMouseMode();
                    showToolbar();
                });

                document.getElementById('mode-select').addEventListener('click', () => {
                    isPanMode = false;
                    updateMouseMode();
                    showToolbar();
                });

                document.getElementById('zoom-in').addEventListener('click', () => {
                    setZoom(zoom * 1.25);
                });

                document.getElementById('zoom-out').addEventListener('click', () => {
                    setZoom(zoom * 0.8);
                });

                document.getElementById('zoom-reset').addEventListener('click', () => {
                    zoom = 1;
                    panX = 0;
                    panY = 0;
                    updateTransform();
                });
        """
    }
}
