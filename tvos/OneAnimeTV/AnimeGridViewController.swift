import UIKit

final class AnimeGridViewController: UICollectionViewController {
    private let service = OneAnimeService()
    private var allItems: [AnimeInfo] = []
    private var items: [AnimeInfo] = []

    init() {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            ))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(250)),
                subitem: item,
                count: 4
            )
            group.interItemSpacing = .fixed(34)
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 48, leading: 80, bottom: 80, trailing: 80)
            section.interGroupSpacing = 42
            return section
        }
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "oneAnime"
        collectionView.backgroundColor = UIColor(red: 0.018, green: 0.022, blue: 0.032, alpha: 1)
        collectionView.register(AnimeCardCell.self, forCellWithReuseIdentifier: AnimeCardCell.reuseID)
        collectionView.remembersLastFocusedIndexPath = true

        load()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimeCardCell.reuseID, for: indexPath) as! AnimeCardCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let anime = items[indexPath.item]
        let controller = LoadingViewController(title: anime.name)
        navigationController?.pushViewController(controller, animated: true)

        Task {
            do {
                let resource = try await service.resolveVideo(for: anime)
                await MainActor.run {
                    controller.play(resource: resource, title: anime.name)
                }
            } catch {
                await MainActor.run {
                    controller.show(error: error)
                }
            }
        }
    }

    private func load() {
        Task {
            do {
                let result = try await service.fetchAnimeList()
                await MainActor.run {
                    allItems = result
                    items = result
                    collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    showLoadError(error)
                }
            }
        }
    }

    private func showLoadError(_ error: Error) {
        let alert = UIAlertController(title: "加载失败", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in self?.load() })
        present(alert, animated: true)
    }
}
