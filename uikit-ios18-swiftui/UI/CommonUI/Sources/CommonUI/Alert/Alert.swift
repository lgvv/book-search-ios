import UIKit

@MainActor
public struct Alert {
    let title: String?
    let message: String?
    let actions: [AlertAction]

    public init(
        title: String? = nil,
        message: String? = nil,
        actions: [AlertAction] = []
    ) {
        self.title = title
        self.message = message
        self.actions = actions.isEmpty ? [.confirm()] : actions
    }
}

public extension Alert {
    static func notice(
        title: String? = nil,
        message: String,
        confirmTitle: String = "확인",
        onConfirm: (() -> Void)? = nil
    ) -> Alert {
        Alert(
            title: title,
            message: message,
            actions: [.confirm(title: confirmTitle, handler: onConfirm)]
        )
    }

    static func retry(
        title: String? = nil,
        message: String,
        retryTitle: String = "다시 시도",
        cancelTitle: String = "닫기",
        onRetry: @escaping () -> Void
    ) -> Alert {
        Alert(
            title: title,
            message: message,
            actions: [
                AlertAction(title: retryTitle, style: .normal, handler: onRetry),
                .cancel(title: cancelTitle)
            ]
        )
    }

    static func confirmDestructive(
        title: String? = nil,
        message: String? = nil,
        actionTitle: String,
        cancelTitle: String = "취소",
        onConfirm: @escaping () -> Void
    ) -> Alert {
        Alert(
            title: title,
            message: message,
            actions: [
                .destructive(title: actionTitle, handler: onConfirm),
                .cancel(title: cancelTitle)
            ]
        )
    }
}
