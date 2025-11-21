import UIKit
import Foundation
import Testing

@testable import ImageLoader

struct ImageDownsamplingTests {

    private func pngData(width: CGFloat, height: CGFloat) -> Data {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: {
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                return format
            }()
        )
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.pngData()!
    }

    @Test
    func 목표크기를주면_원본보다작게디코드한다() throws {
        let data = self.pngData(width: 1_000, height: 1_500)

        let image = try #require(
            ImageDownsampling.decode(data, pixelSize: CGSize(width: 45, height: 80))
        )

        let pixels = try #require(image.cgImage)
        #expect(pixels.width < 1_000)
        #expect(pixels.height < 1_500)
    }

    @Test
    func 짧은변까지영역을덮도록_긴변을계산한다() throws {
        let data = self.pngData(width: 1_000, height: 1_000)

        let image = try #require(
            ImageDownsampling.decode(data, pixelSize: CGSize(width: 45, height: 80))
        )

        let pixels = try #require(image.cgImage)
        #expect(pixels.width >= 80)
        #expect(pixels.height >= 80)
    }

    @Test
    func 원본이영역보다작으면_확대하지않는다() throws {
        let data = self.pngData(width: 40, height: 60)

        let image = try #require(
            ImageDownsampling.decode(data, pixelSize: CGSize(width: 400, height: 600))
        )

        let pixels = try #require(image.cgImage)
        #expect(pixels.width == 40)
        #expect(pixels.height == 60)
    }

    @Test
    func 목표크기가없으면_원본크기로디코드한다() throws {
        let data = self.pngData(width: 200, height: 300)

        let image = try #require(ImageDownsampling.decode(data, pixelSize: nil))

        let pixels = try #require(image.cgImage)
        #expect(pixels.width == 200)
        #expect(pixels.height == 300)
    }

    @Test
    func 목표크기가0이면_원본크기로디코드한다() throws {
        let data = self.pngData(width: 200, height: 300)

        let image = try #require(ImageDownsampling.decode(data, pixelSize: .zero))

        let pixels = try #require(image.cgImage)
        #expect(pixels.width == 200)
    }

    @Test
    func 이미지가아닌데이터는_nil을돌려준다() {
        let data = Data("이건 이미지가 아니다".utf8)

        let image = ImageDownsampling.decode(data, pixelSize: CGSize(width: 45, height: 80))

        #expect(image == nil)
    }

    @Test
    func 빈데이터는_nil을돌려준다() {
        let image = ImageDownsampling.decode(Data(), pixelSize: nil)

        #expect(image == nil)
    }
}
