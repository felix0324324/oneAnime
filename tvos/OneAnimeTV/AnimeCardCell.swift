import UIKit

final class AnimeCardCell: UICollectionViewCell {
    static let reuseID = "AnimeCardCell"

    private let titleLabel = UILabel()
    private let episodeLabel = BadgeLabel()
    private let seasonLabel = BadgeLabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(white: 1, alpha: 0.08)
        contentView.layer.cornerRadius = 24
        contentView.layer.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        subtitleLabel.font = .systemFont(ofSize: 22, weight: .medium)
        subtitleLabel.textColor = UIColor(white: 1, alpha: 0.72)
        subtitleLabel.numberOfLines = 1

        let badges = UIStackView(arrangedSubviews: [episodeLabel, seasonLabel])
        badges.axis = .horizontal
        badges.spacing = 12

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, UIView(), badges])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations {
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
            self.contentView.backgroundColor = self.isFocused
                ? UIColor(red: 0.18, green: 0.38, blue: 0.95, alpha: 1)
                : UIColor(white: 1, alpha: 0.08)
        }
    }

    func configure(with anime: AnimeInfo) {
        titleLabel.text = anime.name
        episodeLabel.text = anime.episode
        seasonLabel.text = anime.year + anime.season
        subtitleLabel.text = anime.subtitle.isEmpty ? "anime1.me #\(anime.id)" : anime.subtitle
    }
}

final class BadgeLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 18, weight: .semibold)
        textColor = .white
        backgroundColor = UIColor(white: 1, alpha: 0.16)
        layer.cornerRadius = 12
        layer.masksToBounds = true
        textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 28, height: size.height + 14)
    }
}
