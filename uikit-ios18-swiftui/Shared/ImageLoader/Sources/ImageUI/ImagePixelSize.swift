import CoreGraphics

enum ImagePixelSize {
    static func from(_ points: CGSize, displayScale: CGFloat) -> CGSize {
        let scale = max(displayScale, 1)
        return CGSize(width: points.width * scale, height: points.height * scale)
    }
}
