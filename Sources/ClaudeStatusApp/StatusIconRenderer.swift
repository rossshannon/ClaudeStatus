import AppKit
import ClaudeStatusCore

enum StatusIconRenderer {
    static func image(for severity: ServiceSeverity) -> NSImage {
        let size = NSSize(width: 24, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        drawBaseIcon(in: NSRect(x: 0, y: 1.5, width: size.width, height: 15), severity: severity)

        image.unlockFocus()
        image.isTemplate = severity == .operational
        image.accessibilityDescription = "Claude status \(severity.displayName)"
        return image
    }

    private static func colour(for severity: ServiceSeverity) -> NSColor {
        switch severity {
        case .operational:
            .labelColor
        case .degraded, .unknown:
            NSColor(calibratedRed: 0.96, green: 0.66, blue: 0.16, alpha: 1.0)
        case .outage:
            NSColor(calibratedRed: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)
        }
    }

    private static func drawBaseIcon(in rect: NSRect, severity: ServiceSeverity) {
        let sourceSize = NSSize(width: 900, height: 566)
        let scale = min(rect.width / sourceSize.width, rect.height / sourceSize.height)
        let fitted = NSRect(
            x: rect.midX - (sourceSize.width * scale / 2),
            y: rect.midY - (sourceSize.height * scale / 2),
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )

        func scaledRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
            NSRect(
                x: fitted.minX + x * scale,
                y: fitted.maxY - (y + height) * scale,
                width: width * scale,
                height: height * scale
            )
        }

        func scaledPoint(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(
                x: fitted.minX + x * scale,
                y: fitted.maxY - y * scale
            )
        }

        colour(for: severity).setFill()

        // Coordinates trace the supplied base image's orange silhouette.
        let body = NSBezierPath()
        body.appendRect(scaledRect(113, 3, 672, 222))
        body.appendRect(scaledRect(0, 225, 897, 116))
        body.appendRect(scaledRect(113, 341, 672, 113))
        body.appendRect(scaledRect(168, 454, 57, 109))
        body.appendRect(scaledRect(280, 454, 57, 109))
        body.appendRect(scaledRect(560, 454, 58, 109))
        body.appendRect(scaledRect(673, 454, 57, 109))
        body.fill()

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.setBlendMode(.clear)

        NSColor.black.setFill()
        NSColor.black.setStroke()

        NSBezierPath(rect: scaledRect(225, 119, 55, 105)).fill()
        NSBezierPath(rect: scaledRect(618, 119, 55, 106)).fill()
        NSBezierPath(ovalIn: scaledRect(444, 319, 31, 31)).fill()

        let lineWidth = 32 * scale

        let leftBrow = NSBezierPath()
        leftBrow.lineWidth = lineWidth
        leftBrow.lineCapStyle = .round
        leftBrow.lineJoinStyle = .round
        leftBrow.move(to: scaledPoint(166, 89))
        leftBrow.curve(
            to: scaledPoint(313, 109),
            controlPoint1: scaledPoint(207, 35),
            controlPoint2: scaledPoint(265, 20)
        )
        leftBrow.stroke()

        let rightBrow = NSBezierPath()
        rightBrow.lineWidth = lineWidth
        rightBrow.lineCapStyle = .round
        rightBrow.lineJoinStyle = .round
        rightBrow.move(to: scaledPoint(535, 102))
        rightBrow.curve(
            to: scaledPoint(616, 110),
            controlPoint1: scaledPoint(567, 108),
            controlPoint2: scaledPoint(594, 116)
        )
        rightBrow.curve(
            to: scaledPoint(676, 53),
            controlPoint1: scaledPoint(642, 98),
            controlPoint2: scaledPoint(655, 73)
        )
        rightBrow.stroke()

        context.restoreGState()
    }
}
