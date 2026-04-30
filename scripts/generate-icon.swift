#!/usr/bin/env swift
// Generates assets/AppIcon.iconset/*.png and runs iconutil to produce
// assets/AppIcon.icns. Re-run any time the icon design changes.
//
// Design: rounded squircle in a deep indigo gradient, with three stacked
// chevrons (sharpening upward) in a warm tinted highlight. Reads cleanly
// at 16pt in the menu bar / Finder list and pops in the dock at 1024.

import AppKit
import Foundation

let iconsetEntries: [(filename: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = projectRoot.appendingPathComponent("assets/AppIcon.iconset")
let icnsURL    = projectRoot.appendingPathComponent("assets/AppIcon.icns")
try? FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func render(size pixels: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ) else { return nil }

    let prevContext = NSGraphicsContext.current
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.current = prevContext }

    let s = CGFloat(pixels)
    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    let radius = s * 0.225
    let body = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Background gradient — deep indigo top to nearly-black bottom.
    let bgTop    = NSColor(red: 0.18, green: 0.13, blue: 0.36, alpha: 1.0)
    let bgBottom = NSColor(red: 0.04, green: 0.03, blue: 0.11, alpha: 1.0)
    if let gradient = NSGradient(colors: [bgTop, bgBottom]) {
        gradient.draw(in: body, angle: -90)
    }

    // Stacked-chevron sharpening mark, three strokes pointing up.
    let strokeColor = NSColor(red: 1.00, green: 0.76, blue: 0.43, alpha: 1.0)
    let strokeWidth   = max(1.0, s * 0.075)
    let chevronWidth  = s * 0.42
    let chevronHeight = s * 0.18
    let chevronGap    = chevronHeight * 0.55
    let centerX = s / 2
    let baseY   = s * 0.30

    for i in 0..<3 {
        let y = baseY + CGFloat(i) * (chevronHeight + chevronGap)
        let path = NSBezierPath()
        path.move(to: NSPoint(x: centerX - chevronWidth / 2, y: y))
        path.line(to: NSPoint(x: centerX, y: y + chevronHeight))
        path.line(to: NSPoint(x: centerX + chevronWidth / 2, y: y))
        path.lineWidth     = strokeWidth
        path.lineCapStyle  = .round
        path.lineJoinStyle = .round
        // Top chevron strongest; lower ones progressively dimmer for a
        // "sharpening up" read.
        let alpha: CGFloat = i == 2 ? 1.0 : (i == 1 ? 0.78 : 0.50)
        strokeColor.withAlphaComponent(alpha).setStroke()
        path.stroke()
    }

    // Subtle inner highlight along the top edge.
    let highlight = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
                                 xRadius: radius, yRadius: radius)
    NSColor.white.withAlphaComponent(0.06).setStroke()
    highlight.lineWidth = max(0.5, s * 0.004)
    highlight.stroke()

    return rep.representation(using: .png, properties: [:])
}

for entry in iconsetEntries {
    guard let data = render(size: entry.size) else {
        FileHandle.standardError.write(Data("Failed to render \(entry.filename)\n".utf8))
        exit(1)
    }
    let url = iconsetURL.appendingPathComponent(entry.filename)
    try data.write(to: url)
}

let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", "-o", icnsURL.path, iconsetURL.path]
try proc.run()
proc.waitUntilExit()
guard proc.terminationStatus == 0 else {
    FileHandle.standardError.write(Data("iconutil failed (exit \(proc.terminationStatus))\n".utf8))
    exit(1)
}
print("→ wrote \(icnsURL.path)")
