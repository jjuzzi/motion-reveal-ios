import AppKit
import CoreText

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL = root.appending(path: "MotionReveal/Assets.xcassets/AppIcon.appiconset/motion-reveal-icon.png")
let fontURL = URL(fileURLWithPath: NSHomeDirectory()).appending(path: "Library/Fonts/NeuethingFamilyTest-SemiBold.otf")

CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

let size = CGSize(width: 1024, height: 1024)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Could not create bitmap context")
}
bitmap.size = size

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func drawText(_ text: String, fontSize: CGFloat, color: NSColor, rect: CGRect, kern: CGFloat = 0) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let font = NSFont(name: "NeuethingSansTest-SemiBold", size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .semibold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
        .kern: kern
    ]
    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

func drawRoundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    color.setFill()
    path.fill()
}

func drawRadialGlow(center: CGPoint, radius: CGFloat, color: NSColor) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    let components = color.usingColorSpace(.deviceRGB) ?? color
    let colors = [
        components.withAlphaComponent(components.alphaComponent).cgColor,
        components.withAlphaComponent(0).cgColor
    ] as CFArray
    let locations: [CGFloat] = [0, 1]
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
    context.saveGState()
    context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    context.restoreGState()
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let bounds = CGRect(origin: .zero, size: size)
NSGraphicsContext.current?.imageInterpolation = .high

let blue = color(92, 190, 246)
let cream = color(255, 242, 216)
let pink = color(255, 162, 201)

blue.setFill()
NSBezierPath(rect: bounds).fill()

drawRadialGlow(center: CGPoint(x: 720, y: 260), radius: 540, color: color(255, 162, 201, 0.16))
drawRadialGlow(center: CGPoint(x: 260, y: 760), radius: 520, color: color(255, 255, 255, 0.18))

let shadow = NSShadow()
shadow.shadowColor = color(18, 75, 112, 0.28)
shadow.shadowBlurRadius = 28
shadow.shadowOffset = CGSize(width: 0, height: -12)
shadow.set()

NSGraphicsContext.current?.saveGraphicsState()
shadow.set()
drawText("l", fontSize: 546, color: cream, rect: CGRect(x: 396, y: 166, width: 292, height: 620), kern: -20)
drawText("p", fontSize: 574, color: cream, rect: CGRect(x: 216, y: 150, width: 396, height: 640), kern: -22)
NSGraphicsContext.current?.restoreGraphicsState()

drawRoundedRect(CGRect(x: 640, y: 318, width: 34, height: 34), radius: 17, color: pink.withAlphaComponent(0.92))

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon PNG")
}

try png.write(to: outputURL, options: .atomic)
print(outputURL.path)
