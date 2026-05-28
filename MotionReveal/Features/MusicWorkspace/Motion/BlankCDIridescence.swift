import CoreMotion
import QuartzCore
import SwiftUI

@MainActor
final class MotionLightModel: NSObject, ObservableObject {
    @Published var x: CGFloat = 0
    @Published var y: CGFloat = 0

    private let motion = CMMotionManager()
    private var displayLink: CADisplayLink?
    private var targetX: CGFloat = 0
    private var targetY: CGFloat = 0
    private var pointerX: CGFloat = 0
    private var pointerY: CGFloat = 0
    private var pointerHeat: CGFloat = 0
    private var lastFrameTimestamp: CFTimeInterval = 0
    private var isRunning = false

    func start() {
        guard !isRunning, motion.isDeviceMotionAvailable else { return }
        isRunning = true
        lastFrameTimestamp = 0
        startDisplayLink()
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }

            let roll = CGFloat(data.attitude.roll)
            let pitch = CGFloat(data.attitude.pitch)
            let gyroX = Self.clamp(roll / 0.24, -1, 1)
            let gyroY = Self.clamp(-pitch / 0.30, -1, 1)
            let pointerWeight = 0.52 * self.pointerHeat
            let gyroWeight = 1 - pointerWeight
            self.targetX = gyroX * gyroWeight + self.pointerX * pointerWeight
            self.targetY = gyroY * gyroWeight + self.pointerY * pointerWeight
        }
    }

    func stop() {
        isRunning = false
        motion.stopDeviceMotionUpdates()
        displayLink?.invalidate()
        displayLink = nil
        lastFrameTimestamp = 0
    }

    func pointerMoved(_ location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        pointerX = Self.clamp(((location.x / size.width) - 0.5) * 2, -1, 1)
        pointerY = Self.clamp(((location.y / size.height) - 0.5) * 2, -1, 1)
        pointerHeat = 1
    }

    private func startDisplayLink() {
        displayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(stepFrame(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func stepFrame(_ link: CADisplayLink) {
        guard isRunning else { return }
        let dt: CGFloat
        if lastFrameTimestamp == 0 {
            dt = CGFloat(link.duration)
        } else {
            dt = CGFloat(max(0.001, min(0.033, link.timestamp - lastFrameTimestamp)))
        }
        lastFrameTimestamp = link.timestamp

        pointerHeat *= pow(0.12, dt)
        let response = 1 - exp(-dt * 15.5)
        let nextX = x + (targetX - x) * response
        let nextY = y + (targetY - y) * response

        guard abs(nextX - x) > 0.0006 || abs(nextY - y) > 0.0006 else { return }
        x = nextX
        y = nextY
    }

    private static func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        min(high, max(low, value))
    }
}

struct BlankCDIridescenceMotionPolicy: Equatable {
    let reactsToMotion: Bool
    let reduceMotion: Bool
    let isUITestLaunch: Bool

    init(
        reactsToMotion: Bool,
        reduceMotion: Bool,
        launchArguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.reactsToMotion = reactsToMotion
        self.reduceMotion = reduceMotion
#if DEBUG
        isUITestLaunch = launchArguments.contains(DebugLaunchStateReset.resetArgument)
#else
        isUITestLaunch = false
#endif
    }

    var usesLiveMotion: Bool {
        reactsToMotion && !reduceMotion && !isUITestLaunch
    }
}

struct BlankCDIridescenceMaterial: Equatable {
    let x: CGFloat
    let y: CGFloat

    init(lightX: CGFloat, lightY: CGFloat) {
        x = Self.clamp(lightX, -1, 1)
        y = Self.clamp(lightY, -1, 1)
    }

    var tiltAmount: CGFloat {
        min(1, hypot(x, y))
    }

    var lightPoint: UnitPoint {
        UnitPoint(x: 0.5 + x * 0.46, y: 0.42 + y * 0.38)
    }

    var reflectionEndRadius: CGFloat {
        0.105 - tiltAmount * 0.034
    }

    var shineOpacity: Double {
        Double(0.56 + min(0.38, tiltAmount * 0.48))
    }

    var spectralOpacity: Double {
        Double(0.64 + min(0.34, tiltAmount * 0.52))
    }

    var spectralAngleDegrees: Double {
        118 + Double(x * 124 - y * 86)
    }

    var spectralOffset: CGSize {
        CGSize(width: x * 0.152, height: y * 0.132)
    }

    var spectralBlurRatio: CGFloat {
        0.013 + tiltAmount * 0.010
    }

    var reflectionBandStart: UnitPoint {
        UnitPoint(x: 0.12 + x * 0.24, y: 0.08 + y * 0.22)
    }

    var reflectionBandEnd: UnitPoint {
        UnitPoint(x: 0.88 + x * 0.20, y: 0.92 + y * 0.18)
    }

    var grooveOpacity: Double {
        Double(0.18 + tiltAmount * 0.16)
    }

    var edgeAlpha: Double {
        Double(0.38 + abs(x) * 0.48)
    }

    var rimGlowPoint: UnitPoint {
        UnitPoint(x: 0.42 + x * 0.24, y: 0.38 + y * 0.20)
    }

    private static func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        min(high, max(low, value))
    }
}

struct BlankCDIridescenceView: View {
    let reactsToMotion: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var light = MotionLightModel()

    init(reactsToMotion: Bool = true) {
        self.reactsToMotion = reactsToMotion
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let motionEnabled = shouldUseLiveMotion
            let x = motionEnabled ? light.x : 0
            let y = motionEnabled ? light.y : 0
            let material = BlankCDIridescenceMaterial(lightX: x, lightY: y)

            ZStack {
                discBase(material: material, size: size)
                spectralWash(material: material)
                    .opacity(material.spectralOpacity)
                    .blur(radius: size * material.spectralBlurRatio)
                    .offset(
                        x: material.spectralOffset.width * size,
                        y: material.spectralOffset.height * size
                    )
                    .blendMode(.screen)
                grooveRings(opacity: material.grooveOpacity)
                edgeAndHole(material: material, size: size)
            }
            .frame(width: size, height: size)
            .compositingGroup()
            .mask {
                CompactDiscFaceShape(centerHoleRatio: 0.245)
                    .fill(style: FillStyle(eoFill: true))
            }
            .overlay {
                centerHoleBevel(material: material, size: size)
            }
            .rotation3DEffect(.degrees(Double(-y * 14)), axis: (x: 1, y: 0, z: 0), perspective: 0.72)
            .rotation3DEffect(.degrees(Double(x * 19)), axis: (x: 0, y: 1, z: 0), perspective: 0.72)
            .rotationEffect(.degrees(Double(x * 3.2 - y * 1.6)))
            .shadow(color: .black.opacity(0.16), radius: size * 0.075, x: 0, y: size * 0.065)
            .shadow(color: .black.opacity(0.10), radius: size * 0.018, x: 0, y: 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard motionEnabled else { return }
                        light.pointerMoved(value.location, in: CGSize(width: size, height: size))
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if motionEnabled {
                    light.start()
                }
            }
            .onChange(of: motionEnabled) { _, isEnabled in
                if isEnabled {
                    light.start()
                } else {
                    light.stop()
                }
            }
            .onDisappear { light.stop() }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var shouldUseLiveMotion: Bool {
        BlankCDIridescenceMotionPolicy(
            reactsToMotion: reactsToMotion,
            reduceMotion: reduceMotion
        )
        .usesLiveMotion
    }

    private func discBase(material: BlankCDIridescenceMaterial, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(red: 0.97, green: 0.98, blue: 1.00),
                            Color(red: 0.65, green: 0.95, blue: 1.00),
                            Color(red: 0.97, green: 0.69, blue: 1.00),
                            Color(red: 1.00, green: 0.94, blue: 0.65),
                            Color(red: 0.65, green: 1.00, blue: 0.78),
                            Color(red: 0.75, green: 0.82, blue: 1.00),
                            Color(red: 1.00, green: 0.73, blue: 0.86),
                            Color(red: 0.98, green: 1.00, blue: 1.00),
                            Color(red: 0.97, green: 0.98, blue: 1.00)
                        ],
                        center: .center,
                        startAngle: .degrees(material.spectralAngleDegrees),
                        endAngle: .degrees(material.spectralAngleDegrees + 360)
                    )
                )
                .saturation(1.08)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(material.shineOpacity), .clear],
                        center: material.lightPoint,
                        startRadius: 0,
                        endRadius: size * material.reflectionEndRadius
                    )
                )
                .blendMode(.screen)
        }
        .overlay(
            RadialGradient(
                colors: [
                    .white.opacity(0.90),
                    Color(red: 0.85, green: 0.90, blue: 0.94).opacity(0.34),
                    Color(red: 0.50, green: 0.58, blue: 0.64).opacity(0.18),
                    .white.opacity(0.64)
                ],
                center: UnitPoint(x: 0.46, y: 0.42),
                startRadius: 0,
                endRadius: size * 0.82
            )
        )
    }

    private func grooveRings(opacity: Double) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = min(size.width, size.height) / 2
            let start = outer * 0.20
            let end = outer * 0.72

            var radius = start
            while radius < end {
                let rect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(opacity)),
                    lineWidth: 0.55
                )
                context.stroke(
                    Path(ellipseIn: rect.insetBy(dx: 1.2, dy: 1.2)),
                    with: .color(Color(red: 0.25, green: 0.33, blue: 0.41).opacity(0.035)),
                    lineWidth: 0.45
                )
                radius += 2.4
            }
        }
        .blendMode(.overlay)
    }

    private func spectralWash(material: BlankCDIridescenceMaterial) -> some View {
        let angle = Angle(degrees: material.spectralAngleDegrees)

        return Circle()
            .fill(
                AngularGradient(
                    colors: [
                        .clear,
                        Color(red: 0.36, green: 0.88, blue: 1.00).opacity(0.78),
                        Color(red: 1.00, green: 0.50, blue: 0.92).opacity(0.74),
                        Color(red: 1.00, green: 0.95, blue: 0.42).opacity(0.70),
                        Color(red: 0.45, green: 1.00, blue: 0.78).opacity(0.72),
                        Color(red: 0.70, green: 0.62, blue: 1.00).opacity(0.64),
                        .clear
                    ],
                    center: .center,
                    startAngle: angle,
                    endAngle: angle + .degrees(360)
                )
            )
	            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.10),
                        .init(color: Color(red: 0.58, green: 0.94, blue: 1.00).opacity(0.28), location: 0.17),
                        .init(color: .white.opacity(0.98), location: 0.24),
                        .init(color: Color(red: 1.00, green: 0.58, blue: 0.88).opacity(0.30), location: 0.31),
                        .init(color: .clear, location: 0.45)
                    ],
                    startPoint: material.reflectionBandStart,
                    endPoint: material.reflectionBandEnd
                )
                .blur(radius: 0.8)
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(red: 0.35, green: 0.92, blue: 1.00).opacity(0.42),
                        Color(red: 1.00, green: 0.55, blue: 0.88).opacity(0.28),
                        .clear
                    ],
                    center: material.lightPoint,
                    startRadius: 0,
                    endRadius: 150
                )
                .blendMode(.screen)
            )
            .scaleEffect(1.22)
            .saturation(2.12)
    }

    private func edgeAndHole(material: BlankCDIridescenceMaterial, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .strokeBorder(.white.opacity(0.70), lineWidth: 1)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.05), lineWidth: size * 0.07)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            .white.opacity(material.edgeAlpha),
                            .clear,
                            .clear,
                            Color(red: 0.64, green: 0.88, blue: 1.00).opacity(0.30)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(Circle())
                )
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.76), lineWidth: size * 0.014)
                        .scaleEffect(0.735)
                )
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.86), lineWidth: size * 0.010)
                        .scaleEffect(0.39)
                )
        }
    }

    private func centerHoleBevel(material: BlankCDIridescenceMaterial, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .strokeBorder(.white.opacity(0.54), lineWidth: size * 0.034)
                .frame(width: size * 0.335, height: size * 0.335)
                .blur(radius: size * 0.002)
                .blendMode(.screen)

            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.82),
                            .white.opacity(0.10),
                            Color(red: 0.34, green: 0.42, blue: 0.48).opacity(0.36),
                            .white.opacity(0.64)
                        ],
                        startPoint: material.reflectionBandStart,
                        endPoint: material.reflectionBandEnd
                    ),
                    lineWidth: size * 0.016
                )
                .frame(width: size * 0.25, height: size * 0.25)
                .shadow(color: .white.opacity(0.42), radius: size * 0.05)
                .shadow(color: .black.opacity(0.22), radius: size * 0.022, x: 0, y: size * 0.006)
        }
        .allowsHitTesting(false)
    }
}

private struct CompactDiscFaceShape: Shape {
    let centerHoleRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let outerRect = CGRect(
            x: rect.midX - side / 2,
            y: rect.midY - side / 2,
            width: side,
            height: side
        )
        let holeSide = side * centerHoleRatio
        let holeRect = CGRect(
            x: rect.midX - holeSide / 2,
            y: rect.midY - holeSide / 2,
            width: holeSide,
            height: holeSide
        )

        var path = Path()
        path.addEllipse(in: outerRect)
        path.addEllipse(in: holeRect)
        return path
    }
}

struct BlankCDDemoScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.00),
                    Color(red: 0.96, green: 0.97, blue: 0.96),
                    .white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            BlankCDIridescenceView()
                .frame(width: 260, height: 260)
        }
    }
}
