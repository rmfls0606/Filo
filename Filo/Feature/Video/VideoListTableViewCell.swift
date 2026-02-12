import UIKit
import SnapKit
import Kingfisher

final class VideoListTableViewCell: UITableViewCell {
    private let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.backgroundColor = GrayStyle.gray75.color
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray15.color
        label.numberOfLines = 2
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 2
        return label
    }()

    private let metadataLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 1
        label.textAlignment = .right
        return label
    }()

    private let textStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 6
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureHierarchy()
        configureLayout()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        thumbnailImageView.kf.cancelDownloadTask()
    }

    func configure(_ item: VideoResponseDTO) {
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        metadataLabel.text = "조회수 \(item.viewCount)회 · 좋아요 \(item.likeCount)"
        setThumbnail(urlString: item.thumbnailURL)
    }

    private func configureHierarchy() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(textStackView)

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(descriptionLabel)
        textStackView.addArrangedSubview(metadataLabel)
    }

    private func configureLayout() {
        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(8)
            make.height.equalTo(thumbnailImageView.snp.width).multipliedBy(9.0 / 16.0)
        }

        textStackView.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    private func setThumbnail(urlString: String) {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            guard let url = URL(string: urlString) else { return }
            thumbnailImageView.kf.indicatorType = .activity
            thumbnailImageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.3)),
                    .requestModifier(RequestModifier.modifer)
                ]
            )
            return
        }

        thumbnailImageView.setKFImage(urlString: urlString)
    }
}
