import UIKit

final class FollowViewController: UICollectionViewController {
    private var items: [AnimeInfo] = []

    init() {
        super.init(collectionViewLayout: AnimeGridLayout.make())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "关注"
        collectionView.backgroundColor = UIColor(red: 0.018, green: 0.022, blue: 0.032, alpha: 1)
        collectionView.register(AnimeCardCell.self, forCellWithReuseIdentifier: AnimeCardCell.reuseID)
        collectionView.remembersLastFocusedIndexPath = true
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
        navigationController?.pushViewController(AnimeDetailViewController(anime: items[indexPath.item]), animated: true)
    }
}

extension FollowViewController: TVTabContentReloading {
    func reloadData() {
        items = FollowStore.all()
        collectionView.reloadData()
    }
}
