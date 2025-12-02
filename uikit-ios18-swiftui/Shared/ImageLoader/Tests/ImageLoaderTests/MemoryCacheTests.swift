import UIKit
import Foundation
import Testing

@testable import ImageLoader

struct MemoryCacheTests {

    private let coverURL = URL(string: "https://picsum.photos/seed/1/200/300")!

    private func makeImage(_ side: CGFloat = 10) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    @Test
    func 저장한이미지를_같은URL과크기로읽을수있다() {
        let sut = MemoryCache()
        let image = self.makeImage()
        let size = CGSize(width: 45, height: 80)

        sut.store(image, for: self.coverURL, pixelSize: size)

        #expect(sut.image(for: self.coverURL, pixelSize: size) === image)
    }

    @Test
    func 저장한적없는URL은_nil이다() {
        let sut = MemoryCache()

        #expect(sut.image(for: self.coverURL, pixelSize: nil) == nil)
    }

    @Test
    func 같은URL이라도_디코드크기가다르면다른항목이다() {
        let sut = MemoryCache()
        let listImage = self.makeImage(10)
        let detailImage = self.makeImage(20)

        sut.store(listImage, for: self.coverURL, pixelSize: CGSize(width: 45, height: 80))
        sut.store(detailImage, for: self.coverURL, pixelSize: CGSize(width: 180, height: 260))

        #expect(sut.image(for: self.coverURL, pixelSize: CGSize(width: 45, height: 80)) === listImage)
        #expect(sut.image(for: self.coverURL, pixelSize: CGSize(width: 180, height: 260)) === detailImage)
    }

    @Test
    func 크기를주지않은항목은_크기를준항목과별개다() {
        let sut = MemoryCache()
        let fullSizeImage = self.makeImage(10)

        sut.store(fullSizeImage, for: self.coverURL, pixelSize: nil)

        #expect(sut.image(for: self.coverURL, pixelSize: nil) === fullSizeImage)
        #expect(sut.image(for: self.coverURL, pixelSize: CGSize(width: 45, height: 80)) == nil)
    }

    @Test
    func 소수점크기는_정수로접어같은키로본다() {
        let sut = MemoryCache()
        let image = self.makeImage()

        sut.store(image, for: self.coverURL, pixelSize: CGSize(width: 45.4, height: 80.2))

        #expect(sut.image(for: self.coverURL, pixelSize: CGSize(width: 45.0, height: 80.0)) === image)
    }

    @Test
    func URL이다르면_같은크기라도다른항목이다() {
        let sut = MemoryCache()
        let otherCoverURL = URL(string: "https://picsum.photos/seed/2/200/300")!
        let image = self.makeImage()
        let size = CGSize(width: 45, height: 80)

        sut.store(image, for: self.coverURL, pixelSize: size)

        #expect(sut.image(for: otherCoverURL, pixelSize: size) == nil)
    }

    @Test
    func 개수상한을넘게넣으면_일부가퇴출된다() {
        let sut = MemoryCache(countLimit: 5)

        for index in 0 ..< 50 {
            let url = URL(string: "https://picsum.photos/seed/\(index)/200/300")!
            sut.store(self.makeImage(), for: url, pixelSize: nil)
        }

        let survivors = (0 ..< 50).filter { index in
            let url = URL(string: "https://picsum.photos/seed/\(index)/200/300")!
            return sut.image(for: url, pixelSize: nil) != nil
        }
        #expect(survivors.count < 50)
    }

    @Test
    func 메모리경고를받으면_전부비운다() {
        let sut = MemoryCache()
        sut.store(self.makeImage(), for: self.coverURL, pixelSize: nil)
        #expect(sut.image(for: self.coverURL, pixelSize: nil) != nil)

        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        #expect(sut.image(for: self.coverURL, pixelSize: nil) == nil)
    }
}
