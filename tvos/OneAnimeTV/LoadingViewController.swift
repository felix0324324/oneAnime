import AVKit
import UIKit

final class LoadingViewController: UIViewController {
    private let statusLabel = UILabel()
    private let animeTitle: String
    private let service = OneAnimeService()

    init(title: String) {
        animeTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = animeTitle
        view.backgroundColor = .black
        statusLabel.text = "正在解析视频..."
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 34, weight: .semibold)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func play(resource: VideoResource, title: String, animeName: String? = nil, episode: Int? = nil) {
        let asset = AVURLAsset(
            url: resource.url,
            options: [
                "AVURLAssetHTTPHeaderFieldsKey": [
                    "User-Agent": OneAnimeAPI.userAgent,
                    "Referer": OneAnimeAPI.animeBaseURL.absoluteString,
                    "Cookie": resource.cookie
                ]
            ]
        )
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.title = title
        attachDanmakuIfNeeded(to: controller, player: player, animeName: animeName, episode: episode)
        if let navigationController {
            var stack = navigationController.viewControllers
            if !stack.isEmpty {
                stack.removeLast()
            }
            stack.append(controller)
            navigationController.setViewControllers(stack, animated: true)
        } else {
            present(controller, animated: true)
        }
        player.play()
    }

    func show(error: Error) {
        statusLabel.text = error.localizedDescription
    }

    private func attachDanmakuIfNeeded(
        to controller: AVPlayerViewController,
        player: AVPlayer,
        animeName: String?,
        episode: Int?
    ) {
        guard let animeName, let episode else {
            return
        }

        Task {
            let comments = (try? await service.fetchDanmaku(title: animeName, episode: episode)) ?? []
            guard !comments.isEmpty else {
                return
            }
            await MainActor.run {
                controller.loadViewIfNeeded()
                guard let container = controller.contentOverlayView else {
                    return
                }
                let overlay = DanmakuOverlayView(player: player, comments: comments)
                overlay.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(overlay)
                NSLayoutConstraint.activate([
                    overlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    overlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    overlay.topAnchor.constraint(equalTo: container.topAnchor),
                    overlay.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.55)
                ])
            }
        }
    }
}
