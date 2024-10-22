import UIKit

@MainActor
public struct AlertAction {
    public enum Style {
        case normal
        case cancel
        case destructive
    }

    let title: String
    let style: Style
    let handler: (() -> Void)?

    public init(
        title: String,
        style: Style = .normal,
        handler: (() -> Void)? = nil
    ) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

public extension AlertAction {
    static func confirm(
        title: String = "확인",
        handler: (() -> Void)? = nil
    ) -> AlertAction {
        AlertAction(title: title, style: .normal, handler: handler)
    }

    static func cancel(
        title: String = "취소",
        handler: (() -> Void)? = nil
    ) -> AlertAction {
        AlertAction(title: title, style: .cancel, handler: handler)
    }

    static func destructive(
        title: String,
        handler: @escaping () -> Void
    ) -> AlertAction {
        AlertAction(title: title, style: .destructive, handler: handler)
    }
}

extension AlertAction.Style {
    var uiStyle: UIAlertAction.Style {
        switch self {
        case .normal: .default
        case .cancel: .cancel
        case .destructive: .destructive
        }
    }
}
