import UIKit

enum AppTab: Int, CaseIterable {
    case search
    case favorite

    var title: String {
        switch self {
        case .search: "검색"
        case .favorite: "즐겨찾기"
        }
    }

    var systemImage: String {
        switch self {
        case .search: "magnifyingglass"
        case .favorite: "heart"
        }
    }
}
