import AVKit
import UIKit

final class LoadingViewController: UIViewController {
    private let statusLabel = UILabel()
    private let animeTitle: String

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

    func play(resource: VideoResource, title: String) {
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
        navigationController?.setViewControllers([navigationController!.viewControllers.first!, controller], animated: true)
        player.play()
    }

    func show(error: Error) {
        statusLabel.text = error.localizedDescription
    }
}
