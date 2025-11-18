import UIKit
import XCTest

@testable import ImageLoader

final class ImageDownsamplingTests: XCTestCase {

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

    func test_목표크기를주면_원본보다작게디코드한다() throws {
        let data = self.pngData(width: 1_000, height: 1_500)

        let image = try XCTUnwrap(
            ImageDownsampling.decode(data, pixelSize: CGSize(width: 45, height: 80))
        )

        let pixels = try XCTUnwrap(image.cgImage)
        XCTAssertLessThan(pixels.width, 1_000)
        XCTAssertLessThan(pixels.height, 1_500)
    }

    func test_짧은변까지영역을덮도록_긴변을계산한다() throws {
        let data = self.pngData(width: 1_000, height: 1_000)

        let image = try XCTUnwrap(
            ImageDownsampling.decode(data, pixelSize: CGSize(width: 45, height: 80))
        )

        let pixels = try XCTUnwrap(image.cgImage)
        XCTAssertGreaterThanOrEqual(pixels.width, 80)
        XCTAssertGreaterThanOrEqual(pixels.height, 80)
    }

    func test_원본이영역보다작으면_확대하지않는다() throws {
        let data = self.pngData(width: 40, height: 60)

        let image = try XCTUnwrap(
            ImageDownsampling.decode(data, pixelSize: CGSize(width: 400, height: 600))
        )

        let pixels = try XCTUnwrap(image.cgImage)
        XCTAssertEqual(pixels.width, 40)
        XCTAssertEqual(pixels.height, 60)
    }

    func test_목표크기가없으면_원본크기로디코드한다() throws {
        let data = self.pngData(width: 200, height: 300)

        let image = try XCTUnwrap(ImageDownsampling.decode(data, pixelSize: nil))

        let pixels = try XCTUnwrap(image.cgImage)
        XCTAssertEqual(pixels.width, 200)
        XCTAssertEqual(pixels.height, 300)
    }

    func test_목표크기가0이면_원본크기로디코드한다() throws {
        let data = self.pngData(width: 200, height: 300)

        let image = try XCTUnwrap(ImageDownsampling.decode(data, pixelSize: .zero))

        let pixels = try XCTUnwrap(image.cgImage)
        XCTAssertEqual(pixels.width, 200)
    }

    func test_이미지가아닌데이터는_nil을돌려준다() {
        let data = Data("이건 이미지가 아니다".utf8)

        let image = ImageDownsampling.decode(data, pixelSize: CGSize(width: 45, height: 80))

        XCTAssertNil(image)
    }

    func test_빈데이터는_nil을돌려준다() {
        let image = ImageDownsampling.decode(Data(), pixelSize: nil)

        XCTAssertNil(image)
    }
}
