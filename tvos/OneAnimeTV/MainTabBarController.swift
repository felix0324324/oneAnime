import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        view.backgroundColor = .black

        viewControllers = [
            nav(AnimeGridViewController(), title: "热门", icon: "play.tv"),
            searchController(),
            nav(FeatureViewController(title: "时间表", message: "Uses anime1.me season pages from the Flutter timeline feature."), title: "时间表", icon: "calendar"),
            nav(FollowViewController(), title: "关注", icon: "heart"),
            nav(HistoryViewController(), title: "历史", icon: "clock"),
            nav(FeatureViewController(title: "设置", message: "Native TV settings should map to existing oneAnime player options."), title: "设置", icon: "gearshape")
        ]
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        guard presses.first?.type == .playPause else {
            return
        }
        (topMostViewController() as? TVTabContentReloading)?.reloadData()
    }

    private func nav(_ root: UIViewController, title: String, icon: String) -> UINavigationController {
        root.title = title
        let controller = UINavigationController(rootViewController: root)
        controller.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), selectedImage: nil)
        controller.tabBarItem.accessibilityIdentifier = title
        return controller
    }

    private func searchController() -> UIViewController {
        let results = AnimeSearchResultsViewController()
        let search = UISearchController(searchResultsController: results)
        search.searchResultsUpdater = results
        search.searchBar.placeholder = "搜索热门"
        let controller = UISearchContainerViewController(searchController: search)
        controller.title = "搜索"
        controller.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "magnifyingglass"), selectedImage: nil)
        controller.tabBarItem.accessibilityIdentifier = "搜索"
        return controller
    }
}

extension MainTabBarController: UITabBarControllerDelegate {}
