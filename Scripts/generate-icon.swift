import AppKit
import CoreGraphics

// Palette from the Code and Run shared design system.
let navy = NSColor(red: 0x1E/255.0, green: 0x3A/255.0, blue: 0x8A/255.0, alpha: 1)
let navyDark = NSColor(red: 0x14/255.0, green: 0x28/255.0, blue: 0x60/255.0, alpha: 1)
let orange = NSColor(red: 0xFC/255.0, green: 0x4C/255.0, blue: 0x02/255.0, alpha: 1)
let orangeLight = NSColor(red: 0xFF/255.0, green: 0x7A/255.0, blue: 0x3D/255.0, alpha: 1)
let white = NSColor.white

func drawIcon(pixelSize: Int) -> NSBitmapImageRep {
    let size = CGFloat(pixelSize)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx

    // macOS "squircle" background with a subtle vertical gradient.
    let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.2237
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
    let gradient = NSGradient(starting: navy, ending: navyDark)!
    gradient.draw(in: bgPath, angle: -90)

    // Hourglass frame proportions, centered in the canvas.
    let margin = size * 0.24
    let glassWidth = size - margin * 2
    let top = size - margin
    let bottom = margin
    let midY = size / 2
    let neckHalfWidth = glassWidth * 0.05
    let capHeight = glassWidth * 0.12

    func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x, y: y) }

    // Top cap bar.
    let topCap = NSBezierPath(roundedRect: NSRect(x: margin, y: top - capHeight, width: glassWidth, height: capHeight), xRadius: capHeight * 0.4, yRadius: capHeight * 0.4)
    white.setFill()
    topCap.fill()

    // Bottom cap bar.
    let bottomCap = NSBezierPath(roundedRect: NSRect(x: margin, y: bottom, width: glassWidth, height: capHeight), xRadius: capHeight * 0.4, yRadius: capHeight * 0.4)
    bottomCap.fill()

    // Glass body: two triangles meeting at the neck.
    let glassPath = NSBezierPath()
    glassPath.move(to: point(margin, top - capHeight))
    glassPath.line(to: point(size - margin, top - capHeight))
    glassPath.line(to: point(midY + neckHalfWidth, midY))
    glassPath.line(to: point(size - margin, bottom + capHeight))
    glassPath.line(to: point(margin, bottom + capHeight))
    glassPath.line(to: point(midY - neckHalfWidth, midY))
    glassPath.close()
    white.withAlphaComponent(0.92).setFill()
    glassPath.fill()

    // Sand: settled at the bottom + drop near the top, in the brand orange.
    let sandInset = glassWidth * 0.12
    let bottomSand = NSBezierPath()
    bottomSand.move(to: point(midY - neckHalfWidth, midY))
    bottomSand.line(to: point(midY + neckHalfWidth, midY))
    bottomSand.line(to: point(size - margin - sandInset, bottom + capHeight + sandInset * 0.4))
    bottomSand.line(to: point(margin + sandInset, bottom + capHeight + sandInset * 0.4))
    bottomSand.close()
    orange.setFill()
    bottomSand.fill()

    let topSand = NSBezierPath()
    let topSandDrop = glassWidth * 0.16
    topSand.move(to: point(margin + sandInset * 1.4, top - capHeight - sandInset * 0.3))
    topSand.line(to: point(size - margin - sandInset * 1.4, top - capHeight - sandInset * 0.3))
    topSand.line(to: point(midY + neckHalfWidth * 1.6, midY - topSandDrop))
    topSand.line(to: point(midY - neckHalfWidth * 1.6, midY - topSandDrop))
    topSand.close()
    orangeLight.setFill()
    topSand.fill()

    NSGraphicsContext.current?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func writePNG(_ rep: NSBitmapImageRep, to path: String) {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG for \(path)")
    }
    do {
        try data.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    } catch {
        fatalError("Could not write \(path): \(error)")
    }
}

guard CommandLine.arguments.count > 1 else {
    fatalError("Usage: swift Scripts/generate-icon.swift <output-iconset-dir>")
}
let outDir = CommandLine.arguments[1]
let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for entry in sizes {
    let rep = drawIcon(pixelSize: entry.px)
    writePNG(rep, to: "\(outDir)/\(entry.name).png")
}
