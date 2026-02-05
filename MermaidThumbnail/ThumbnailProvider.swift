import QuickLookThumbnailing
import WebKit
import AppKit

class ThumbnailProvider: QLThumbnailProvider {

    private static let supportedExtensions = ["mmd", "mermaid"]

    // Bundled mermaid.js
    private static let mermaidJS: String = {
        let bundle = Bundle(for: ThumbnailProvider.self)
        if let url = bundle.url(forResource: "mermaid.min", withExtension: "js"),
           let js = try? String(contentsOf: url, encoding: .utf8) {
            return js
        }
        return "console.error('mermaid.min.js not found');"
    }()

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let fileURL = request.fileURL
        let ext = fileURL.pathExtension.lowercased()

        guard Self.supportedExtensions.contains(ext) else {
            handler(nil, NSError(domain: "MermaidQuickLook", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported file type"]))
            return
        }

        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            handler(nil, NSError(domain: "MermaidQuickLook", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not read file"]))
            return
        }

        let maxSize = request.maximumSize
        let scale = request.scale

        // Create reply with drawing handler
        let reply = QLThumbnailReply(contextSize: maxSize) { context -> Bool in
            // Draw a simple placeholder thumbnail
            // For a real implementation, we'd need to render mermaid and capture it
            self.drawThumbnail(context: context, size: maxSize, code: content)
            return true
        }

        handler(reply, nil)
    }

    private func drawThumbnail(context: CGContext, size: CGSize, code: String) {
        let w = size.width
        let h = size.height

        // Padding for the document shape
        let padding = min(w, h) * 0.08
        let docW = w - padding * 2
        let docH = h - padding * 2
        let docX = padding
        let docY = padding

        // Fold corner size
        let foldSize = docW * 0.18

        // Draw shadow
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -2), blur: 8, color: NSColor.black.withAlphaComponent(0.3).cgColor)

        // Document shape path (with folded corner)
        context.setFillColor(NSColor.white.cgColor)
        context.move(to: CGPoint(x: docX, y: docY))
        context.addLine(to: CGPoint(x: docX, y: docY + docH))
        context.addLine(to: CGPoint(x: docX + docW - foldSize, y: docY + docH))
        context.addLine(to: CGPoint(x: docX + docW, y: docY + docH - foldSize))
        context.addLine(to: CGPoint(x: docX + docW, y: docY))
        context.closePath()
        context.fillPath()
        context.restoreGState()

        // Document border
        context.setStrokeColor(NSColor(white: 0.75, alpha: 1).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: docX, y: docY))
        context.addLine(to: CGPoint(x: docX, y: docY + docH))
        context.addLine(to: CGPoint(x: docX + docW - foldSize, y: docY + docH))
        context.addLine(to: CGPoint(x: docX + docW, y: docY + docH - foldSize))
        context.addLine(to: CGPoint(x: docX + docW, y: docY))
        context.closePath()
        context.strokePath()

        // Folded corner
        context.setFillColor(NSColor(white: 0.92, alpha: 1).cgColor)
        context.move(to: CGPoint(x: docX + docW - foldSize, y: docY + docH))
        context.addLine(to: CGPoint(x: docX + docW - foldSize, y: docY + docH - foldSize))
        context.addLine(to: CGPoint(x: docX + docW, y: docY + docH - foldSize))
        context.closePath()
        context.fillPath()

        // Fold corner border
        context.setStrokeColor(NSColor(white: 0.75, alpha: 1).cgColor)
        context.move(to: CGPoint(x: docX + docW - foldSize, y: docY + docH))
        context.addLine(to: CGPoint(x: docX + docW - foldSize, y: docY + docH - foldSize))
        context.addLine(to: CGPoint(x: docX + docW, y: docY + docH - foldSize))
        context.strokePath()

        // Content area
        let contentX = docX + docW * 0.12
        let contentY = docY + docH * 0.1
        let contentW = docW * 0.76
        let contentH = docH * 0.7

        // Colors for flowchart
        let nodeColor = NSColor(red: 0, green: 0.71, blue: 0.85, alpha: 1)
        let lineColor = nodeColor.withAlphaComponent(0.8)

        // Scale for nodes
        let nodeW = contentW * 0.35
        let nodeH = contentH * 0.12
        let nodeR = nodeH * 0.3

        // Top node
        let topNode = CGRect(x: contentX + (contentW - nodeW) / 2,
                             y: contentY + contentH * 0.78,
                             width: nodeW, height: nodeH)
        context.setFillColor(nodeColor.cgColor)
        context.addPath(CGPath(roundedRect: topNode, cornerWidth: nodeR, cornerHeight: nodeR, transform: nil))
        context.fillPath()

        // Diamond
        let diamondCenterX = contentX + contentW / 2
        let diamondCenterY = contentY + contentH * 0.55
        let diamondSize = contentH * 0.14
        context.setFillColor(nodeColor.withAlphaComponent(0.9).cgColor)
        context.move(to: CGPoint(x: diamondCenterX, y: diamondCenterY + diamondSize))
        context.addLine(to: CGPoint(x: diamondCenterX + diamondSize, y: diamondCenterY))
        context.addLine(to: CGPoint(x: diamondCenterX, y: diamondCenterY - diamondSize))
        context.addLine(to: CGPoint(x: diamondCenterX - diamondSize, y: diamondCenterY))
        context.closePath()
        context.fillPath()

        // Bottom nodes
        let bottomNodeW = nodeW * 0.8
        let bottomNodeH = nodeH * 0.9
        let leftNode = CGRect(x: contentX + contentW * 0.05,
                              y: contentY + contentH * 0.15,
                              width: bottomNodeW, height: bottomNodeH)
        let rightNode = CGRect(x: contentX + contentW - bottomNodeW - contentW * 0.05,
                               y: contentY + contentH * 0.15,
                               width: bottomNodeW, height: bottomNodeH)

        context.setFillColor(nodeColor.withAlphaComponent(0.85).cgColor)
        context.addPath(CGPath(roundedRect: leftNode, cornerWidth: nodeR, cornerHeight: nodeR, transform: nil))
        context.fillPath()
        context.addPath(CGPath(roundedRect: rightNode, cornerWidth: nodeR, cornerHeight: nodeR, transform: nil))
        context.fillPath()

        // Connecting lines
        context.setStrokeColor(lineColor.cgColor)
        context.setLineWidth(max(1.5, contentW * 0.02))
        context.setLineCap(.round)

        // Top to diamond
        context.move(to: CGPoint(x: topNode.midX, y: topNode.minY))
        context.addLine(to: CGPoint(x: diamondCenterX, y: diamondCenterY + diamondSize))
        context.strokePath()

        // Diamond to left
        context.move(to: CGPoint(x: diamondCenterX - diamondSize, y: diamondCenterY))
        context.addLine(to: CGPoint(x: leftNode.midX, y: diamondCenterY))
        context.addLine(to: CGPoint(x: leftNode.midX, y: leftNode.maxY))
        context.strokePath()

        // Diamond to right
        context.move(to: CGPoint(x: diamondCenterX + diamondSize, y: diamondCenterY))
        context.addLine(to: CGPoint(x: rightNode.midX, y: diamondCenterY))
        context.addLine(to: CGPoint(x: rightNode.midX, y: rightNode.maxY))
        context.strokePath()
    }
}
