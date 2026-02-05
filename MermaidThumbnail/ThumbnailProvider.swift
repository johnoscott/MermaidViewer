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
        let scale = min(w, h) / 100  // Scale factor for proportional drawing

        // Draw document background with subtle gradient effect
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // Draw subtle document shadow/border
        context.setFillColor(NSColor(white: 0.95, alpha: 1).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: w, height: h * 0.08))

        // Draw document fold corner
        let foldSize = w * 0.15
        context.setFillColor(NSColor(white: 0.9, alpha: 1).cgColor)
        context.move(to: CGPoint(x: w - foldSize, y: h))
        context.addLine(to: CGPoint(x: w, y: h))
        context.addLine(to: CGPoint(x: w, y: h - foldSize))
        context.closePath()
        context.fillPath()

        // Draw fold line
        context.setStrokeColor(NSColor(white: 0.8, alpha: 1).cgColor)
        context.setLineWidth(scale * 0.5)
        context.move(to: CGPoint(x: w - foldSize, y: h))
        context.addLine(to: CGPoint(x: w, y: h - foldSize))
        context.strokePath()

        // Colors for the flowchart
        let nodeColor = NSColor(red: 0, green: 0.71, blue: 0.85, alpha: 1)  // Teal/cyan
        let nodeColorLight = nodeColor.withAlphaComponent(0.15)
        let lineColor = nodeColor.withAlphaComponent(0.7)

        // Draw flowchart nodes
        let nodeRadius = scale * 4
        let nodeHeight = scale * 10
        let nodeWidth = scale * 22

        // Top node (rounded rect)
        let topNode = CGRect(x: w * 0.5 - nodeWidth/2, y: h * 0.75, width: nodeWidth, height: nodeHeight)
        context.setFillColor(nodeColor.cgColor)
        let topPath = CGPath(roundedRect: topNode, cornerWidth: nodeRadius, cornerHeight: nodeRadius, transform: nil)
        context.addPath(topPath)
        context.fillPath()

        // Diamond (decision node) in middle
        let diamondCenter = CGPoint(x: w * 0.5, y: h * 0.52)
        let diamondSize = scale * 12
        context.setFillColor(nodeColor.withAlphaComponent(0.9).cgColor)
        context.move(to: CGPoint(x: diamondCenter.x, y: diamondCenter.y + diamondSize))
        context.addLine(to: CGPoint(x: diamondCenter.x + diamondSize, y: diamondCenter.y))
        context.addLine(to: CGPoint(x: diamondCenter.x, y: diamondCenter.y - diamondSize))
        context.addLine(to: CGPoint(x: diamondCenter.x - diamondSize, y: diamondCenter.y))
        context.closePath()
        context.fillPath()

        // Bottom left node
        let leftNode = CGRect(x: w * 0.15, y: h * 0.22, width: nodeWidth * 0.8, height: nodeHeight * 0.8)
        context.setFillColor(nodeColor.withAlphaComponent(0.85).cgColor)
        let leftPath = CGPath(roundedRect: leftNode, cornerWidth: nodeRadius, cornerHeight: nodeRadius, transform: nil)
        context.addPath(leftPath)
        context.fillPath()

        // Bottom right node
        let rightNode = CGRect(x: w * 0.85 - nodeWidth * 0.8, y: h * 0.22, width: nodeWidth * 0.8, height: nodeHeight * 0.8)
        context.addPath(CGPath(roundedRect: rightNode, cornerWidth: nodeRadius, cornerHeight: nodeRadius, transform: nil))
        context.fillPath()

        // Draw connecting lines
        context.setStrokeColor(lineColor.cgColor)
        context.setLineWidth(scale * 1.5)
        context.setLineCap(.round)

        // Top to diamond
        context.move(to: CGPoint(x: w * 0.5, y: topNode.minY))
        context.addLine(to: CGPoint(x: w * 0.5, y: diamondCenter.y + diamondSize))
        context.strokePath()

        // Diamond to left
        context.move(to: CGPoint(x: diamondCenter.x - diamondSize, y: diamondCenter.y))
        context.addLine(to: CGPoint(x: leftNode.midX, y: diamondCenter.y))
        context.addLine(to: CGPoint(x: leftNode.midX, y: leftNode.maxY))
        context.strokePath()

        // Diamond to right
        context.move(to: CGPoint(x: diamondCenter.x + diamondSize, y: diamondCenter.y))
        context.addLine(to: CGPoint(x: rightNode.midX, y: diamondCenter.y))
        context.addLine(to: CGPoint(x: rightNode.midX, y: rightNode.maxY))
        context.strokePath()

        // Draw small arrow heads
        let arrowSize = scale * 3
        context.setFillColor(lineColor.cgColor)

        // Arrow to left node
        context.move(to: CGPoint(x: leftNode.midX, y: leftNode.maxY))
        context.addLine(to: CGPoint(x: leftNode.midX - arrowSize, y: leftNode.maxY + arrowSize * 1.5))
        context.addLine(to: CGPoint(x: leftNode.midX + arrowSize, y: leftNode.maxY + arrowSize * 1.5))
        context.closePath()
        context.fillPath()

        // Arrow to right node
        context.move(to: CGPoint(x: rightNode.midX, y: rightNode.maxY))
        context.addLine(to: CGPoint(x: rightNode.midX - arrowSize, y: rightNode.maxY + arrowSize * 1.5))
        context.addLine(to: CGPoint(x: rightNode.midX + arrowSize, y: rightNode.maxY + arrowSize * 1.5))
        context.closePath()
        context.fillPath()

        // Arrow to diamond
        context.move(to: CGPoint(x: w * 0.5, y: diamondCenter.y + diamondSize))
        context.addLine(to: CGPoint(x: w * 0.5 - arrowSize, y: diamondCenter.y + diamondSize + arrowSize * 1.5))
        context.addLine(to: CGPoint(x: w * 0.5 + arrowSize, y: diamondCenter.y + diamondSize + arrowSize * 1.5))
        context.closePath()
        context.fillPath()
    }
}
