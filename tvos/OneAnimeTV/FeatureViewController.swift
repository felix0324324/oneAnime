import UIKit

final class FeatureViewController: UIViewController {
    private let heading: String
    private let detail: String

    init(title: String, message: String) {
        heading = title
        detail = message
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.018, green: 0.022, blue: 0.032, alpha: 1)

        let titleLabel = UILabel()
        titleLabel.text = heading
        titleLabel.font = .systemFont(ofSize: 56, weight: .bold)
        titleLabel.textColor = .white

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .systemFont(ofSize: 28, weight: .regular)
        detailLabel.textColor = UIColor(white: 1, alpha: 0.72)
        detailLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 22
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 120),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -120),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
