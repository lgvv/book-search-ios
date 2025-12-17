import Foundation

protocol DeepLinkParsing: Sendable {
    func parse(_ url: URL) -> (any Route)?
}

extension URL {
    var deepLinkPathISBN: String? {
        let path = self.pathComponents.drop { $0 == "/" }
        if self.host?.lowercased() == "book" {
            return path.first.flatMap(Self.validatedISBN)
        }
        guard path.count >= 2, path.first?.lowercased() == "book" else { return nil }
        let isbn = path[path.index(path.startIndex, offsetBy: 1)]
        return Self.validatedISBN(isbn)
    }

    var deepLinkQueryISBN: String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "isbn" }?
            .value
            .flatMap(Self.validatedISBN)
    }

    private static func validatedISBN(_ raw: String) -> String? {
        let compact = raw.replacingOccurrences(of: "-", with: "")

        func isASCIIDigit(_ character: Character) -> Bool {
            character.isASCII && character.isNumber
        }

        switch compact.count {
        case 13 where compact.allSatisfy(isASCIIDigit):
            return compact
        case 10:
            guard let checkDigit = compact.last,
                  compact.dropLast().allSatisfy(isASCIIDigit),
                  isASCIIDigit(checkDigit) || checkDigit == "X" || checkDigit == "x"
            else { return nil }
            return compact
        default:
            return nil
        }
    }
}
