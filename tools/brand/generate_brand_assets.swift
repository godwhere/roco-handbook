import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum BrandAssetError: Error {
    case cannotReadSource(URL)
    case cannotCreateContext
    case cannotCreateImage
    case cannotCreateDestination(URL)
    case cannotWrite(URL)
}

func loadImage(_ url: URL) throws -> CGImage {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw BrandAssetError.cannotReadSource(url)
    }
    return image
}

func makeContext(size: Int, alpha: Bool) throws -> CGContext {
    let info: CGImageAlphaInfo = alpha ? .premultipliedLast : .noneSkipLast
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: info.rawValue
    ) else {
        throw BrandAssetError.cannotCreateContext
    }
    context.interpolationQuality = .high
    return context
}

func drawGradient(in context: CGContext, size: Int) {
    let colors = [
        CGColor(red: 0.035, green: 0.18, blue: 0.43, alpha: 1),
        CGColor(red: 0.10, green: 0.49, blue: 0.87, alpha: 1),
        CGColor(red: 0.30, green: 0.72, blue: 0.98, alpha: 1),
    ] as CFArray
    let locations: [CGFloat] = [0, 0.58, 1]
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: colors,
        locations: locations
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: CGFloat(size), y: CGFloat(size)),
        options: []
    )
}

func drawCharacter(_ image: CGImage, in context: CGContext, size: Int, scale: CGFloat) {
    let canvas = CGFloat(size)
    let targetWidth = canvas * scale
    let aspect = CGFloat(image.height) / CGFloat(image.width)
    let targetHeight = targetWidth * aspect
    let rect = CGRect(
        x: (canvas - targetWidth) / 2,
        y: canvas * 0.09,
        width: targetWidth,
        height: targetHeight
    )
    context.draw(image, in: rect)
}

func makeIcon(source: CGImage, size: Int) throws -> CGImage {
    let context = try makeContext(size: size, alpha: false)
    drawGradient(in: context, size: size)
    let canvas = CGFloat(size)
    context.setShadow(
        offset: CGSize(width: 0, height: -canvas * 0.025),
        blur: canvas * 0.055,
        color: CGColor(gray: 0, alpha: 0.28)
    )
    context.setFillColor(CGColor(red: 0.96, green: 0.985, blue: 1, alpha: 0.96))
    context.fillEllipse(in: CGRect(
        x: canvas * 0.105,
        y: canvas * 0.13,
        width: canvas * 0.79,
        height: canvas * 0.79
    ))
    context.setShadow(offset: .zero, blur: 0, color: nil)
    context.setStrokeColor(CGColor(red: 1, green: 0.79, blue: 0.16, alpha: 1))
    context.setLineWidth(canvas * 0.028)
    context.strokeEllipse(in: CGRect(
        x: canvas * 0.105,
        y: canvas * 0.13,
        width: canvas * 0.79,
        height: canvas * 0.79
    ))
    drawCharacter(source, in: context, size: size, scale: 0.78)
    guard let image = context.makeImage() else {
        throw BrandAssetError.cannotCreateImage
    }
    return image
}

func makeLaunchMark(source: CGImage, size: Int) throws -> CGImage {
    let context = try makeContext(size: size, alpha: true)
    context.clear(CGRect(x: 0, y: 0, width: size, height: size))
    let canvas = CGFloat(size)
    context.setFillColor(CGColor(red: 0.91, green: 0.965, blue: 1, alpha: 0.94))
    context.fillEllipse(in: CGRect(
        x: canvas * 0.08,
        y: canvas * 0.08,
        width: canvas * 0.84,
        height: canvas * 0.84
    ))
    context.setStrokeColor(CGColor(red: 1, green: 0.79, blue: 0.16, alpha: 1))
    context.setLineWidth(canvas * 0.025)
    context.strokeEllipse(in: CGRect(
        x: canvas * 0.08,
        y: canvas * 0.08,
        width: canvas * 0.84,
        height: canvas * 0.84
    ))
    drawCharacter(source, in: context, size: size, scale: 0.74)
    guard let image = context.makeImage() else {
        throw BrandAssetError.cannotCreateImage
    }
    return image
}

func resize(_ image: CGImage, size: Int, alpha: Bool) throws -> CGImage {
    let context = try makeContext(size: size, alpha: alpha)
    context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    guard let result = context.makeImage() else {
        throw BrandAssetError.cannotCreateImage
    }
    return result
}

func writePNG(_ image: CGImage, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw BrandAssetError.cannotCreateDestination(url)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw BrandAssetError.cannotWrite(url)
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = try loadImage(
    root.appendingPathComponent("app/assets/wiki/v1/pets/illustrations/JL_dimo.png")
)
let icon = try makeIcon(source: source, size: 1024)
let launch = try makeLaunchMark(source: source, size: 600)

let iosIconDirectory = root.appendingPathComponent(
    "app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
)
let iosIcons: [(String, Int)] = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]
for (name, size) in iosIcons {
    try writePNG(try resize(icon, size: size, alpha: false), to: iosIconDirectory.appendingPathComponent(name))
}

let launchDirectory = root.appendingPathComponent(
    "app/ios/Runner/Assets.xcassets/LaunchImage.imageset"
)
for (name, size) in [
    ("LaunchImage.png", 200),
    ("LaunchImage@2x.png", 400),
    ("LaunchImage@3x.png", 600),
] {
    try writePNG(try resize(launch, size: size, alpha: true), to: launchDirectory.appendingPathComponent(name))
}

let androidIcons: [(String, Int)] = [
    ("mipmap-mdpi", 48),
    ("mipmap-hdpi", 72),
    ("mipmap-xhdpi", 96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi", 192),
]
for (directory, size) in androidIcons {
    let url = root.appendingPathComponent(
        "app/android/app/src/main/res/\(directory)/ic_launcher.png"
    )
    try writePNG(try resize(icon, size: size, alpha: false), to: url)
}
try writePNG(
    try resize(launch, size: 384, alpha: true),
    to: root.appendingPathComponent(
        "app/android/app/src/main/res/drawable-nodpi/launch_image.png"
    )
)

print("Generated formal iOS and Android brand assets from the frozen Dimo illustration.")
