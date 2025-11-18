import UIKit

import DesignSystem

public extension UIViewController {
    func presentAlert(_ alert: Alert, animated: Bool = true) {
        let target = self.topmostPresentedViewController
        let controller = alert.makeViewController()

        guard let coordinator = target.transitionCoordinator else {
            target.present(controller, animated: animated)
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in
            target.present(controller, animated: animated)
        }
    }

    var topmostPresentedViewController: UIViewController {
        var top = self
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}

extension Alert {
    func makeViewController() -> UIAlertController {
        let controller = UIAlertController(
            title: self.title,
            message: self.message,
            preferredStyle: .alert
        )
        controller.view.tintColor = .dsTint

        for action in self.actions {
            controller.addAction(
                UIAlertAction(title: action.title, style: action.style.uiStyle) { _ in
                    action.handler?()
                }
            )
        }
        return controller
    }
}
