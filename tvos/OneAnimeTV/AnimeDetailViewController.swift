import UIKit

final class AnimeDetailViewController: UIViewController {
    private let anime: AnimeInfo
    private let service = OneAnimeService()
    private var episodes: [AnimeEpisode] = []
    private var preferredEpisode: Int

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let followButton = UIButton(type: .system)
    private let collectionView: UICollectionView

    init(anime: AnimeInfo, episode: Int = 1) {
        self.anime = anime
        preferredEpisode = max(episode, 1)

        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(88)),
            subitem: item,
            count: 6
        )
        group.interItemSpacing = .fixed(22)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 22
        section.contentInsets = NSDirectionalEdgeInsets(top: 32, leading: 0, bottom: 80, trailing: 0)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(section: section))

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredFocusedView: UIView? {
        playButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = anime.name
        view.backgroundColor = UIColor(red: 0.018, green: 0.022, blue: 0.032, alpha: 1)

        titleLabel.text = anime.name
        titleLabel.font = .systemFont(ofSize: 54, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        subtitleLabel.text = detailText
        subtitleLabel.font = .systemFont(ofSize: 26, weight: .medium)
        subtitleLabel.textColor = UIColor(white: 1, alpha: 0.74)
        subtitleLabel.numberOfLines = 3

        statusLabel.text = "正在载入集数..."
        statusLabel.font = .systemFont(ofSize: 24, weight: .medium)
        statusLabel.textColor = UIColor(white: 1, alpha: 0.6)

        configure(button: playButton, title: "播放")
        configure(button: followButton, title: followTitle)
        playButton.addTarget(self, action: #selector(playPreferredEpisode), for: .primaryActionTriggered)
        followButton.addTarget(self, action: #selector(toggleFollow), for: .primaryActionTriggered)

        let buttons = UIStackView(arrangedSubviews: [playButton, followButton])
        buttons.axis = .horizontal
        buttons.spacing = 24

        let header = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, buttons, statusLabel])
        header.axis = .vertical
        header.spacing = 24
        header.translatesAutoresizingMaskIntoConstraints = false

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.register(EpisodeCell.self, forCellWithReuseIdentifier: EpisodeCell.reuseID)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 80),
            header.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80),
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),

            collectionView.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 32),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadEpisodes()
    }

    private var detailText: String {
        let source = anime.subtitle.isEmpty ? "anime1.me #\(anime.id)" : anime.subtitle
        return "\(source)\n\(anime.year)\(anime.season) · \(anime.episode)"
    }

    private var followTitle: String {
        FollowStore.contains(anime) ? "取消关注" : "关注"
    }

    private func configure(button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 30, weight: .semibold)
        button.contentEdgeInsets = UIEdgeInsets(top: 18, left: 42, bottom: 18, right: 42)
    }

    private func loadEpisodes() {
        Task {
            do {
                let result = try await service.fetchEpisodes(for: anime)
                await MainActor.run {
                    episodes = result
                    preferredEpisode = min(preferredEpisode, max(result.count, 1))
                    statusLabel.text = result.isEmpty ? "没有可播放集数" : "共 \(result.count) 集"
                    collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    statusLabel.text = error.localizedDescription
                }
            }
        }
    }

    @objc private func toggleFollow() {
        _ = FollowStore.toggle(anime)
        followButton.setTitle(followTitle, for: .normal)
    }

    @objc private func playPreferredEpisode() {
        guard let episode = episodes.first(where: { $0.number == preferredEpisode }) ?? episodes.first else {
            return
        }
        play(episode)
    }

    private func play(_ episode: AnimeEpisode) {
        preferredEpisode = episode.number
        HistoryStore.add(anime: anime, episode: episode)

        let loading = LoadingViewController(title: "\(anime.name) \(episode.title)")
        navigationController?.pushViewController(loading, animated: true)

        Task {
            do {
                let resource = try await service.resolveVideo(token: episode.token)
                await MainActor.run {
                    loading.play(
                        resource: resource,
                        title: "\(anime.name) \(episode.title)",
                        animeName: anime.name,
                        episode: episode.number
                    )
                }
            } catch {
                await MainActor.run {
                    loading.show(error: error)
                }
            }
        }
    }
}

extension AnimeDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        episodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EpisodeCell.reuseID, for: indexPath) as! EpisodeCell
        cell.configure(with: episodes[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        play(episodes[indexPath.item])
    }
}
