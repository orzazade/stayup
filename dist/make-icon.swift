// Renders the stayup app icon (dark squircle + glowing green power button) to a
// 1024×1024 master PNG. Run: swift dist/make-icon.swift  → dist/icon-master.png
import AppKit

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no ctx") }

let full = NSRect(x: 0, y: 0, width: size, height: size)

// macOS "squircle" background
let corner = size * 0.2237
let bg = NSBezierPath(roundedRect: full, xRadius: corner, yRadius: corner)
bg.addClip()
NSGradient(colors: [
    NSColor(srgbRed: 0.17, green: 0.17, blue: 0.19, alpha: 1),
    NSColor(srgbRed: 0.086, green: 0.086, blue: 0.094, alpha: 1)
])!.draw(in: full, angle: -90)

let center = NSPoint(x: size / 2, y: size / 2)

// Green glow halo
NSGradient(colors: [
    NSColor(srgbRed: 0.19, green: 0.82, blue: 0.35, alpha: 0.55),
    NSColor(srgbRed: 0.19, green: 0.82, blue: 0.35, alpha: 0.0)
])!.draw(fromCenter: center, radius: 0, toCenter: center, radius: size * 0.40, options: [])

// Green power disc (top-lit radial)
let d = size * 0.54
let discRect = NSRect(x: (size - d) / 2, y: (size - d) / 2, width: d, height: d)
ctx.saveGState()
NSBezierPath(ovalIn: discRect).addClip()
let discCenter = NSPoint(x: size / 2, y: size / 2 + d * 0.12)
NSGradient(colors: [
    NSColor(srgbRed: 0.27, green: 0.90, blue: 0.45, alpha: 1),
    NSColor(srgbRed: 0.12, green: 0.62, blue: 0.27, alpha: 1)
])!.draw(fromCenter: discCenter, radius: 0, toCenter: NSPoint(x: size/2, y: size/2), radius: d * 0.62, options: [])
ctx.restoreGState()

// subtle rim
ctx.saveGState()
let rim = NSBezierPath(ovalIn: discRect.insetBy(dx: 1, dy: 1))
rim.lineWidth = 3
NSColor.white.withAlphaComponent(0.18).setStroke()
rim.stroke()
ctx.restoreGState()

// Power glyph (SF Symbol), dark green to match the app
if let sym = NSImage(systemSymbolName: "power", accessibilityDescription: nil)?
    .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: size * 0.32, weight: .medium)) {
    let gs = sym.size
    let gx = (size - gs.width) / 2
    let gy = (size - gs.height) / 2
    let tinted = NSImage(size: gs)
    tinted.lockFocus()
    sym.draw(in: NSRect(origin: .zero, size: gs))
    NSColor(srgbRed: 0.05, green: 0.22, blue: 0.10, alpha: 1).set()
    NSRect(origin: .zero, size: gs).fill(using: .sourceAtop)
    tinted.unlockFocus()
    tinted.draw(in: NSRect(x: gx, y: gy, width: gs.width, height: gs.height))
}

img.unlockFocus()

let outDir = (CommandLine.arguments.count > 1) ? CommandLine.arguments[1] : "."
let out = URL(fileURLWithPath: outDir).appendingPathComponent("icon-master.png")
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { fatalError("encode failed") }
try! png.write(to: out)
print("wrote \(out.path)")
