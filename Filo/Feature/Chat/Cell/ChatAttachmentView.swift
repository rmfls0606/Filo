//
//  ChatAttachmentView.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatAttachmentView: UIView {
    private let imageContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.25)
        return view
    }()

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray15.color
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.isHidden = true
        return label
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
        let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .regular)
        view.image = UIImage(systemName: "doc.fill", withConfiguration: config)
        view.tintColor = GrayStyle.gray0.color
        view.clipsToBounds = true
        view.contentMode = .center
        view.isHidden = true
        return view
    }()

    private var imageLeadingConstraint: Constraint?
    private var imageTrailingConstraint: Constraint?
    private var imageCenterXConstraint: Constraint?
    private var labelLeadingToImage: Constraint?
    private var labelTrailingToImage: Constraint?
    private var labelTrailingConstraint: Constraint?
    private var labelLeadingConstraint: Constraint?

    private var currentURLString: String?
    private var alignThumbnailOnLeft: Bool = true
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureHierarchy() {
        addSubview(imageContainer)
        addSubview(fileNameLabel)
        addSubview(fileBadge)
        addSubview(fileIconView)
        imageContainer.addSubview(imageView)
    }

    private func configureLayout() {
        imageContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.size.equalTo(CGSize(width: 72, height: 72))
            imageLeadingConstraint = make.leading.equalToSuperview().constraint
            imageTrailingConstraint = make.trailing.equalToSuperview().constraint
            imageCenterXConstraint = make.centerX.equalToSuperview().constraint
        }

        fileNameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.top)
            make.bottom.lessThanOrEqualToSuperview()
            labelLeadingToImage = make.leading.equalTo(imageContainer.snp.trailing).offset(8).constraint
            labelTrailingToImage = make.trailing.equalTo(imageContainer.snp.leading).offset(-8).constraint
            labelLeadingConstraint = make.leading.equalToSuperview().constraint
            labelTrailingConstraint = make.trailing.equalToSuperview().constraint
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        fileBadge.snp.makeConstraints { make in
            make.centerX.equalTo(imageContainer)
            make.centerY.equalTo(imageContainer)
            make.width.equalTo(44)
            make.height.equalTo(22)
        }

        fileIconView.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(imageContainer).inset(6)
            make.size.equalTo(12)
        }

        fileNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        fileNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func bind(urlString: String, alignThumbnailOnLeft: Bool) {
        currentURLString = urlString
        self.alignThumbnailOnLeft = alignThumbnailOnLeft
        let ext = Self.fileExtension(from: urlString)
        let isPDF = ext == "pdf"
        let isImage = !isPDF

        if isImage {
            fileBadge.isHidden = true
            fileIconView.isHidden = true
            fileNameLabel.isHidden = true
            fileNameLabel.text = nil
            fileNameLabel.textAlignment = alignThumbnailOnLeft ? .left : .right
            updateLayout(alignThumbnailOnLeft: alignThumbnailOnLeft)
            imageView.setKFImage(urlString: urlString)
        } else if isPDF {
            // Some signed URLs can end with ".pdf" even when payload is an image.
            imageView.setKFImage(urlString: urlString) { [weak self] result in
                guard let self else { return }
                guard self.currentURLString == urlString else { return }
                switch result {
                case .success:
                    self.fileBadge.isHidden = true
                    self.fileIconView.isHidden = true
                    self.fileNameLabel.isHidden = true
                    self.fileNameLabel.text = nil
                    self.imageView.tintColor = nil
                    self.updateLayout(alignThumbnailOnLeft: alignThumbnailOnLeft)
                case .failure:
                    self.fileBadge.isHidden = false
                    self.fileIconView.isHidden = true
                    self.fileNameLabel.isHidden = false
                    self.fileNameLabel.text = Self.fileName(from: urlString)
                    self.fileNameLabel.textAlignment = alignThumbnailOnLeft ? .left : .right
                    self.updateLayout(alignThumbnailOnLeft: alignThumbnailOnLeft)
                    self.imageView.image = UIImage(systemName: "doc")
                    self.imageView.tintColor = GrayStyle.gray60.color
                    self.loadPDFThumbnail(urlString: urlString)
                }
            }
        } else {
            fileBadge.isHidden = false
            fileIconView.isHidden = true
            fileNameLabel.isHidden = false
            fileNameLabel.text = Self.fileName(from: urlString)
            fileNameLabel.textAlignment = alignThumbnailOnLeft ? .left : .right
            updateLayout(alignThumbnailOnLeft: alignThumbnailOnLeft)
            imageView.image = UIImage(systemName: "doc")
            imageView.tintColor = GrayStyle.gray60.color
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let available = max(0, bounds.width - 72 - 8)
        fileNameLabel.preferredMaxLayoutWidth = available
        updateFileNameLineMode(availableWidth: available)
        updateLayout(alignThumbnailOnLeft: alignThumbnailOnLeft)
    }

    private func updateFileNameLineMode(availableWidth: CGFloat) {
        guard let text = fileNameLabel.text, !text.isEmpty, availableWidth > 0 else { return }
        let font = fileNameLabel.font ?? UIFont.systemFont(ofSize: 12)
        let textWidth = ceil((text as NSString).size(withAttributes: [.font: font]).width)
        let fitsSingleLine = textWidth <= availableWidth + 1
        if fitsSingleLine {
            fileNameLabel.numberOfLines = 1
            fileNameLabel.lineBreakMode = .byTruncatingTail
        } else {
            fileNameLabel.numberOfLines = 2
            fileNameLabel.lineBreakMode = .byWordWrapping
        }
    }

    private func updateLayout(alignThumbnailOnLeft: Bool) {
        fileNameLabel.isHidden = fileNameLabel.text?.isEmpty ?? true
        let hasLabel = !fileNameLabel.isHidden

        imageCenterXConstraint?.deactivate()
        if alignThumbnailOnLeft {
            imageLeadingConstraint?.activate()
            imageTrailingConstraint?.deactivate()
            if hasLabel {
                labelLeadingToImage?.activate()
                labelTrailingToImage?.deactivate()
                labelTrailingConstraint?.activate()
                labelLeadingConstraint?.deactivate()
                fileNameLabel.textAlignment = .left
            } else {
                labelLeadingToImage?.deactivate()
                labelTrailingToImage?.deactivate()
                labelLeadingConstraint?.deactivate()
                labelTrailingConstraint?.deactivate()
            }
        } else {
            imageTrailingConstraint?.activate()
            imageLeadingConstraint?.deactivate()
            if hasLabel {
                labelTrailingToImage?.activate()
                labelLeadingToImage?.deactivate()
                labelLeadingConstraint?.activate()
                labelTrailingConstraint?.deactivate()
                fileNameLabel.textAlignment = .right
            } else {
                labelLeadingToImage?.deactivate()
                labelTrailingToImage?.deactivate()
                labelLeadingConstraint?.deactivate()
                labelTrailingConstraint?.deactivate()
            }
        }
    }

    private func loadPDFThumbnail(urlString: String) {
        guard let url = Self.resolveURL(from: urlString) else { return }
        let target = imageView.bounds.size == .zero ? CGSize(width: 72, height: 72) : imageView.bounds.size
        ThumbnailCache.shared.loadPDFThumbnail(url: url, size: target) { [weak self] image in
            guard let self else { return }
            guard self.currentURLString == urlString else { return }
            guard let image else { return }
            self.imageView.image = image
            self.imageView.tintColor = nil
            self.fileBadge.isHidden = true
            self.fileIconView.isHidden = false
        }
    }

    @objc
    private func handleTap() {
        onTap?()
    }
}

private extension ChatAttachmentView {
    static func resolveURL(from urlString: String) -> URL? {
        if let url = URL(string: urlString), url.scheme != nil {
            return url
        }
        let trimmed = urlString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(NetworkConfig.baseURL)/\(trimmed)")
    }

    static func fileName(from urlString: String) -> String {
        if let url = URL(string: urlString) {
            let name = url.lastPathComponent
            if !name.isEmpty {
                return name
            }
        }
        if let components = URLComponents(string: urlString) {
            let name = components.path.split(separator: "/").last.map(String.init) ?? ""
            if !name.isEmpty {
                return name
            }
        }
        if let last = urlString.split(separator: "/").last {
            return String(last).split(separator: "?").first.map(String.init) ?? String(last)
        }
        return urlString
    }

    static func fileExtension(from urlString: String) -> String {
        if let url = URL(string: urlString), !url.pathExtension.isEmpty {
            return url.pathExtension.lowercased()
        }
        if let components = URLComponents(string: urlString) {
            let ext = (components.path as NSString).pathExtension
            if !ext.isEmpty {
                return ext.lowercased()
            }
        }
        let trimmed = urlString.split(separator: "?").first.map(String.init) ?? urlString
        return (trimmed as NSString).pathExtension.lowercased()
    }

    static func isImageFile(extension ext: String) -> Bool {
        return ext != "pdf"
    }
}
