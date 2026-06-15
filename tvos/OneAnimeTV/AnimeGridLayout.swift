import UIKit

enum AnimeGridLayout {
    static func make(columns: Int = 4, itemHeight: CGFloat = 250) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            ))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemHeight)),
                subitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(34)
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 48, leading: 80, bottom: 80, trailing: 80)
            section.interGroupSpacing = 42
            return section
        }
    }
}
