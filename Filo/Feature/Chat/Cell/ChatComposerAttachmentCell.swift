//
//  ChatComposerAttachmentCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatComposerAttachmentCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.25)
        return view
    }()

    private let fileBadge: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray0.color
        label.text = "FILE"
        label.textAlignment = .center
        label.backgroundColor = Brand.deepTurquoise.color
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private let fileIconView: UIImageView = {
        let view = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        view.image = UIImage(systemName: "doc.fill", withConfiguration: config)
        view.tintColor = GrayStyle.gray30.color
        view.clipsToBounds = true
        view.contentMode = .center
        view.isHidden = true
        return view
    }()

    private let removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = GrayStyle.gray45.color
        return button
    }()

    var onRemove: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(fileBadge)
        contentView.addSubview(fileIconView)
        contentView.addSubview(removeButton)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        fileBadge.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(22)
        }

        fileIconView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(6)
            make.size.equalTo(14)
        }

        removeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(4)
            make.size.equalTo(18)
        }

        removeButton.addTarget(self, action: #selector(handleRemove), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(item: ChatAttachmentItem) {
        let isPDF = item.mimeType.lowercased() == "application/pdf" || item.fileName.lowercased().hasSuffix(".pdf")
        if item.isImage, let image = UIImage(data: item.data) {
            imageView.image = image
            fileBadge.isHidden = true
            fileIconView.isHidden = true
        } else if isPDF {
            let target = imageView.bounds.size == .zero ? CGSize(width: 72, height: 72) : imageView.bounds.size
            imageView.image = UIImage(systemName: "doc")
            imageView.tintColor = GrayStyle.gray60.color
            fileBadge.isHidden = true
            fileIconView.isHidden = false
            ThumbnailCache.shared.loadPDFThumbnail(data: item.data, size: target) { [weak self] thumbnail in
                guard let self else { return }
                guard let thumbnail else { return }
                self.imageView.image = thumbnail
                self.imageView.tintColor = nil
            }
        } else {
            imageView.image = UIImage(systemName: "doc")
            imageView.tintColor = GrayStyle.gray60.color
            fileBadge.isHidden = false
            fileIconView.isHidden = true
        }
    }

    @objc private func handleRemove() {
        onRemove?()
    }
}
