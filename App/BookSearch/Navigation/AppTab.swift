import UIKit

enum AppTab: Int, CaseIterable {
    case search
    case favorite
    case memo

    var title: String {
        switch self {
        case .search: "검색"
        case .favorite: "즐겨찾기"
        case .memo: "메모"
        }
    }

    var systemImage: String {
        switch self {
        case .search: "magnifyingglass"
        case .favorite: "heart"
        case .memo: "note.text"
        }
    }
}
