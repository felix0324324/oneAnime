import UIKit

protocol TVTabContentReloading: AnyObject {
    func reloadData()
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
        }
        if let presentedViewController {
            return presentedViewController.topMostViewController()
        }
        return self
    }
}
