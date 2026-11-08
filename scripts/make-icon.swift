// Draws the app icon (a window-switcher palette with the second row selected) as an .icns file.
// Run via `just icon`, which compiles this with the macOS SDK and writes Resources/AppIcon.icns.
import AppKit

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = size / 1024  // design on a 1024 grid

    // Body: Apple's macOS grid puts an 824pt rounded square inside the 1024 canvas.
    let body = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: 185 * s, yRadius: 185 * s)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = 20 * s
    shadow.shadowOffset = NSSize(width: 0, height: -8 * s)
    shadow.set()
    NSColor.black.setFill()
    bodyPath.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: NSColor(srgbRed: 0.36, green: 0.42, blue: 0.98, alpha: 1),
               ending: NSColor(srgbRed: 0.20, green: 0.16, blue: 0.55, alpha: 1))!.draw(in: bodyPath, angle: -90)

    // Palette panel, styled like the real one: light grey, placeholder text, numbered rows with app icons.
    let panel = NSRect(x: 180 * s, y: 215 * s, width: 664 * s, height: 594 * s)
    NSColor(white: 0.86, alpha: 1).setFill()
    NSBezierPath(roundedRect: panel, xRadius: 52 * s, yRadius: 52 * s).fill()

    func bar(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: NSColor) {
        color.setFill()
        NSBezierPath(roundedRect: NSRect(x: x * s, y: y * s, width: width * s, height: height * s),
                     xRadius: height / 2 * s, yRadius: height / 2 * s).fill()
    }

    // "Search windows" placeholder
    bar(222, 712, 250, 34, NSColor(white: 0.66, alpha: 1))
    bar(492, 712, 120, 34, NSColor(white: 0.74, alpha: 1))

    // Window rows; the second is preselected, like the palette's default.
    let rows: [(app: NSColor, title: CGFloat, name: CGFloat)] = [
        (NSColor(srgbRed: 0.93, green: 0.36, blue: 0.62, alpha: 1), 250, 100),
        (NSColor(srgbRed: 0.20, green: 0.74, blue: 0.45, alpha: 1), 300, 80),
        (NSColor(white: 0.15, alpha: 1), 200, 70),
        (NSColor(srgbRed: 0.18, green: 0.50, blue: 0.95, alpha: 1), 230, 90),
    ]
    let digitFont = NSFont.systemFont(ofSize: 40 * s, weight: .semibold)
    for (index, row) in rows.enumerated() {
        let y = 590 - CGFloat(index) * 112
        if index == 1 {
            NSColor(white: 1, alpha: 0.6).setFill()
            NSBezierPath(roundedRect: NSRect(x: 196 * s, y: (y - 30) * s, width: 632 * s, height: 112 * s),
                         xRadius: 22 * s, yRadius: 22 * s).fill()
        }
        let digit = NSAttributedString(string: "\(index + 1)", attributes: [
            .font: digitFont, .foregroundColor: NSColor(white: 0.55, alpha: 1),
        ])
        digit.draw(at: NSPoint(x: 222 * s, y: (y + 26) * s - digitFont.capHeight / 2 + digitFont.descender))
        row.app.setFill()
        NSBezierPath(roundedRect: NSRect(x: 270 * s, y: y * s, width: 52 * s, height: 52 * s), xRadius: 13 * s, yRadius: 13 * s).fill()
        bar(346, y + 12, row.title, 28, NSColor(white: 0.25, alpha: 1))
        bar(346 + row.title + 20, y + 14, row.name, 24, NSColor(white: 0.55, alpha: 1))
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: make-icon <output.icns>\n".data(using: .utf8)!)
    exit(1)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        let png = drawIcon(size: CGFloat(points * scale)).representation(using: .png, properties: [:])!
        try png.write(to: iconset.appendingPathComponent(name))
    }
}
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { exit(iconutil.terminationStatus) }
print("Wrote \(output.path)")
