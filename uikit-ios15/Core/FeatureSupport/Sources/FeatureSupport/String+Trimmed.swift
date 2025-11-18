import Foundation

extension String {
    public var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isBlank: Bool {
        self.trimmed.isEmpty
    }
}
