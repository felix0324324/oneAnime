import UIKit

final class HistoryViewController: UICollectionViewController {
    private var items: [AnimeHistoryRecord] = []

    init() {
        super.init(collectionViewLayout: AnimeGridLayout.make())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "历史"
        collectionView.backgroundColor = UIColor(red: 0.018, green: 0.022, blue: 0.032, alpha: 1)
        collectionView.register(AnimeCardCell.self, forCellWithReuseIdentifier: AnimeCardCell.reuseID)
        collectionView.remembersLastFocusedIndexPath = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "清空", style: .plain, target: self, action: #selector(clearHistory))
        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
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
        let record = items[indexPath.item]
        navigationController?.pushViewController(
            AnimeDetailViewController(anime: record.anime, episode: record.episodeNumber),
            animated: true
        )
    }

    @objc private func clearHistory() {
        HistoryStore.clear()
        reloadData()
    }
}

extension HistoryViewController: TVTabContentReloading {
    func reloadData() {
        items = HistoryStore.all()
        collectionView.reloadData()
    }
}
