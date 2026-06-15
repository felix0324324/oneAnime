import UIKit

final class AnimeSearchResultsViewController: UICollectionViewController, UISearchResultsUpdating {
    private var allItems: [AnimeInfo] = []
    private var items: [AnimeInfo] = []
    private var pendingQuery = ""

    init() {
        super.init(collectionViewLayout: AnimeGridLayout.make())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = UIColor(red: 0.018, green: 0.022, blue: 0.032, alpha: 1)
        collectionView.register(AnimeCardCell.self, forCellWithReuseIdentifier: AnimeCardCell.reuseID)
        collectionView.remembersLastFocusedIndexPath = true
        load()
    }

    func updateSearchResults(for searchController: UISearchController) {
        pendingQuery = searchController.searchBar.text ?? ""
        applyFilter()
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
        let detail = AnimeDetailViewController(anime: items[indexPath.item])
        if let navigationController {
            navigationController.pushViewController(detail, animated: true)
        } else {
            present(UINavigationController(rootViewController: detail), animated: true)
        }
    }

    private func load() {
        Task {
            do {
                let result = try await AnimeLibrary.shared.fetchAnimeList()
                await MainActor.run {
                    allItems = result
                    applyFilter()
                }
            } catch {
                await MainActor.run {
                    items = []
                    collectionView.reloadData()
                }
            }
        }
    }

    private func applyFilter() {
        let query = pendingQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            items = []
            collectionView.reloadData()
            return
        }

        items = allItems.filter { anime in
            [anime.name, anime.subtitle, anime.year, anime.season, anime.episode]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
        collectionView.reloadData()
    }
}

extension AnimeSearchResultsViewController: TVTabContentReloading {
    func reloadData() {
        load()
    }
}
