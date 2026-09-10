import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ScreenshotNormalizationError: Error {
    case noInput
    case invalidCrop(String)
    case cannotRead(URL)
    case cannotCreateContext(URL)
    case cannotCreateImage(URL)
    case cannotCreateDestination(URL)
    case cannotWrite(URL)
}

func normalizeScreenshot(at url: URL, cropTop: Int) throws {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw ScreenshotNormalizationError.cannotRead(url)
    }
    guard cropTop >= 0, cropTop < image.height else {
        throw ScreenshotNormalizationError.invalidCrop("\(cropTop) for \(url.path)")
    }
    let cropRect = CGRect(
        x: 0,
        y: cropTop,
        width: image.width,
        height: image.height - cropTop
    )
    guard let cropped = image.cropping(to: cropRect) else {
        throw ScreenshotNormalizationError.invalidCrop(url.path)
    }
    guard let context = CGContext(
        data: nil,
        width: cropped.width,
        height: cropped.height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        throw ScreenshotNormalizationError.cannotCreateContext(url)
    }
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: cropped.width, height: cropped.height))
    context.draw(
        cropped,
        in: CGRect(x: 0, y: 0, width: cropped.width, height: cropped.height)
    )
    guard let normalized = context.makeImage() else {
        throw ScreenshotNormalizationError.cannotCreateImage(url)
    }

    let temporary = url.deletingLastPathComponent().appendingPathComponent(
        ".\(url.lastPathComponent).rgb-\(ProcessInfo.processInfo.processIdentifier)"
    )
    try? FileManager.default.removeItem(at: temporary)
    guard let destination = CGImageDestinationCreateWithURL(
        temporary as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw ScreenshotNormalizationError.cannotCreateDestination(url)
    }
    CGImageDestinationAddImage(destination, normalized, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw ScreenshotNormalizationError.cannotWrite(url)
    }
    _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
    print(
        "Normalized RGB screenshot: \(url.path) "
            + "(\(cropped.width)×\(cropped.height), crop top \(cropTop))"
    )
}

var arguments = Array(CommandLine.arguments.dropFirst())
var cropTop = 0
if arguments.first == "--crop-top" {
    guard arguments.count >= 3, let value = Int(arguments[1]) else {
        throw ScreenshotNormalizationError.invalidCrop(
            arguments.dropFirst().first ?? "missing"
        )
    }
    cropTop = value
    arguments.removeFirst(2)
}
let paths = arguments
guard !paths.isEmpty else {
    throw ScreenshotNormalizationError.noInput
}
for path in paths {
    try normalizeScreenshot(at: URL(fileURLWithPath: path), cropTop: cropTop)
}
