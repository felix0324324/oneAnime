import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        viewControllers = [
            nav(AnimeGridViewController(), title: "热门", icon: "play.tv"),
            nav(FeatureViewController(title: "时间表", message: "Uses anime1.me season pages from the Flutter timeline feature."), title: "时间表", icon: "calendar"),
            nav(FeatureViewController(title: "关注", message: "Follow data remains owned by the Flutter storage feature."), title: "关注", icon: "heart"),
            nav(FeatureViewController(title: "历史", message: "History storage can be bridged here without changing Flutter behavior."), title: "历史", icon: "clock"),
            nav(FeatureViewController(title: "设置", message: "Native TV settings should map to existing oneAnime player options."), title: "设置", icon: "gearshape")
        ]
    }

    private func nav(_ root: UIViewController, title: String, icon: String) -> UINavigationController {
        root.title = title
        let controller = UINavigationController(rootViewController: root)
        controller.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), selectedImage: nil)
        return controller
    }
}
