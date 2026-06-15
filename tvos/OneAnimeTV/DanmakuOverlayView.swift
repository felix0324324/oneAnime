import AVFoundation
import UIKit

final class DanmakuOverlayView: UIView {
    private var groupedComments: [Int: [DanmakuComment]] = [:]
    private var shownSeconds = Set<Int>()
    private weak var player: AVPlayer?
    private var timeObserver: Any?
    private var row = 0

    init(player: AVPlayer, comments: [DanmakuComment]) {
        self.player = player
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        groupedComments = Dictionary(grouping: comments) { Int($0.time) }
        installObserver(on: player)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
    }

    private func installObserver(on player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.showComments(at: Int(time.seconds))
        }
    }

    private func showComments(at second: Int) {
        guard
            !shownSeconds.contains(second),
            let comments = groupedComments[second],
            !bounds.isEmpty
        else { return }

        shownSeconds.insert(second)
        for (index, comment) in comments.prefix(4).enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.25) { [weak self] in
                self?.animate(comment.text)
            }
        }
    }

    private func animate(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 34, weight: .semibold)
        label.textColor = .white
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.95
        label.layer.shadowRadius = 4
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.sizeToFit()

        let maxRows = max(Int(bounds.height / 56), 1)
        row = (row + 1) % min(maxRows, 8)
        let y = CGFloat(row) * 56 + 24
        label.frame.origin = CGPoint(x: bounds.width + 30, y: y)
        addSubview(label)

        UIView.animate(withDuration: 8.0, delay: 0, options: [.curveLinear]) {
            label.frame.origin.x = -label.bounds.width - 30
        } completion: { _ in
            label.removeFromSuperview()
        }
    }
}
