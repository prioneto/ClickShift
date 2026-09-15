#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.png"
let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Could not create icon drawing context")
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
}

context.clear(CGRect(x: 0, y: 0, width: size, height: size))
context.translateBy(x: 0, y: CGFloat(size))
context.scaleBy(x: 1, y: -1)

context.setFillColor(color(16, 24, 39))
context.addPath(CGPath(
    roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
    cornerWidth: 224,
    cornerHeight: 224,
    transform: nil
))
context.fillPath()

let upper = CGMutablePath()
upper.move(to: CGPoint(x: 282, y: 274))
upper.addLine(to: CGPoint(x: 568, y: 274))
upper.addCurve(to: CGPoint(x: 696, y: 402), control1: CGPoint(x: 644, y: 274), control2: CGPoint(x: 696, y: 326))
upper.addLine(to: CGPoint(x: 696, y: 464))
upper.addCurve(to: CGPoint(x: 588, y: 592), control1: CGPoint(x: 696, y: 537), control2: CGPoint(x: 649, y: 585))
upper.addCurve(to: CGPoint(x: 541, y: 575), control1: CGPoint(x: 570, y: 594), control2: CGPoint(x: 554, y: 588))
upper.addLine(to: CGPoint(x: 450, y: 484))
upper.addCurve(to: CGPoint(x: 413, y: 484), control1: CGPoint(x: 438, y: 472), control2: CGPoint(x: 425, y: 472))
upper.addLine(to: CGPoint(x: 322, y: 575))
upper.addCurve(to: CGPoint(x: 275, y: 592), control1: CGPoint(x: 309, y: 588), control2: CGPoint(x: 293, y: 594))
upper.addCurve(to: CGPoint(x: 167, y: 464), control1: CGPoint(x: 214, y: 585), control2: CGPoint(x: 167, y: 537))
upper.addLine(to: CGPoint(x: 167, y: 402))
upper.addCurve(to: CGPoint(x: 282, y: 274), control1: CGPoint(x: 167, y: 326), control2: CGPoint(x: 219, y: 274))
upper.closeSubpath()
context.setFillColor(color(87, 184, 222))
context.addPath(upper)
context.fillPath()

let lower = CGMutablePath()
lower.move(to: CGPoint(x: 486, y: 558))
lower.addCurve(to: CGPoint(x: 580, y: 516), control1: CGPoint(x: 531, y: 558), control2: CGPoint(x: 552, y: 544))
lower.addCurve(to: CGPoint(x: 629, y: 496), control1: CGPoint(x: 593, y: 503), control2: CGPoint(x: 610, y: 496))
lower.addLine(to: CGPoint(x: 771, y: 496))
lower.addCurve(to: CGPoint(x: 891, y: 616), control1: CGPoint(x: 842, y: 496), control2: CGPoint(x: 891, y: 545))
lower.addLine(to: CGPoint(x: 891, y: 694))
lower.addCurve(to: CGPoint(x: 771, y: 814), control1: CGPoint(x: 891, y: 765), control2: CGPoint(x: 842, y: 814))
lower.addLine(to: CGPoint(x: 548, y: 814))
lower.addCurve(to: CGPoint(x: 428, y: 694), control1: CGPoint(x: 477, y: 814), control2: CGPoint(x: 428, y: 765))
lower.addLine(to: CGPoint(x: 428, y: 632))
lower.addCurve(to: CGPoint(x: 486, y: 558), control1: CGPoint(x: 428, y: 586), control2: CGPoint(x: 440, y: 558))
lower.closeSubpath()

lower.move(to: CGPoint(x: 610, y: 691))
lower.addCurve(to: CGPoint(x: 600, y: 713), control1: CGPoint(x: 598, y: 691), control2: CGPoint(x: 592, y: 705))
lower.addLine(to: CGPoint(x: 663, y: 776))
lower.addCurve(to: CGPoint(x: 693, y: 776), control1: CGPoint(x: 673, y: 786), control2: CGPoint(x: 683, y: 786))
lower.addLine(to: CGPoint(x: 756, y: 713))
lower.addCurve(to: CGPoint(x: 746, y: 691), control1: CGPoint(x: 764, y: 705), control2: CGPoint(x: 758, y: 691))
lower.closeSubpath()

context.setFillColor(color(168, 218, 104))
context.addPath(lower)
context.drawPath(using: .eoFill)

guard let image = context.makeImage() else {
    fatalError("Could not create icon image")
}

let representation = NSBitmapImageRep(cgImage: image)
guard let png = representation.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode icon PNG")
}

try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
