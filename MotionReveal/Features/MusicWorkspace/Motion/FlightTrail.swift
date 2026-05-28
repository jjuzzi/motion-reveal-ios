import SwiftUI

struct FlightTrail: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX * 0.82, y: rect.maxY * 0.86))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX * 0.72, y: rect.minY + 10),
            control: CGPoint(x: rect.midX * 1.08, y: rect.midY * 0.34)
        )
        return path.trimmedPath(from: max(0, progress - 0.42), to: progress)
    }
}
