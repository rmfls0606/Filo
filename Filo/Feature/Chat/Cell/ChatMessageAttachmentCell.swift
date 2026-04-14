//
//  ChatMessageAttachmentCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatMessageAttachmentCell: BaseCollectionViewCell {
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
        label.lineBreakMode = .byCharWrapping
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

    private var currentURLString: String?
    private var alignThumbnailOnLeft: Bool = true
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 8
        stack.distribution = .fill
        return stack
    }()

    private let rowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 0
        stack.distribution = .fill
        return stack
    }()

    private let spacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()

    override func configureHierarchy() {
        contentView.addSubview(rowStack)
        contentView.addSubview(fileBadge)
        contentView.addSubview(fileIconView)
        imageContainer.addSubview(imageView)
        contentStack.addArrangedSubview(imageContainer)
        contentStack.addArrangedSubview(fileNameLabel)
        rowStack.addArrangedSubview(contentStack)
        rowStack.addArrangedSubview(spacerView)
    }
    
    override func configureLayout() {
        rowStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageContainer.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 72, height: 72))
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
        contentStack.setContentHuggingPriority(.required, for: .horizontal)
        contentStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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
            imageView.setKFImage(urlString: urlString, targetSize: imageView.bounds.size)
        } else if isPDF {
            // Signed URLs can have misleading extensions. Try image decode first.
            imageView.setKFImage(urlString: urlString, targetSize: imageView.bounds.size) { [weak self] result in
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
        let available = contentView.bounds.width - 72 - 8
        fileNameLabel.preferredMaxLayoutWidth = max(0, available)
        updateFileNameLineMode(availableWidth: max(0, available))
        updateLayout(alignThumbnailOnLeft: alignThumbnailOnLeft)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentURLString = nil
        fileNameLabel.text = nil
        fileNameLabel.isHidden = true
        fileBadge.isHidden = true
        fileIconView.isHidden = true
        imageView.image = nil
        alignThumbnailOnLeft = true
        updateLayout(alignThumbnailOnLeft: true)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        updateLayout(alignThumbnailOnLeft: alignThumbnailOnLeft)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetHeight: CGFloat = 72
        let targetSize = CGSize(width: UIView.layoutFittingCompressedSize.width, height: targetHeight)
        let size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        )
        attributes.size = CGSize(width: ceil(size.width), height: targetHeight)
        return attributes
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
}

private extension ChatMessageAttachmentCell {
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

    static func displayName(from urlString: String) -> String {
        let name = fileName(from: urlString)
        let trimmed = name.split(separator: "?").first.map(String.init) ?? name
        if let dotIndex = trimmed.lastIndex(of: "."),
           dotIndex > trimmed.startIndex {
            return String(trimmed[..<dotIndex])
        }
        return trimmed
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

    func updateLayout(alignThumbnailOnLeft: Bool) {
        if alignThumbnailOnLeft {
            if contentStack.arrangedSubviews.first !== imageContainer {
                contentStack.removeArrangedSubview(fileNameLabel)
                contentStack.removeArrangedSubview(imageContainer)
                contentStack.addArrangedSubview(imageContainer)
                contentStack.addArrangedSubview(fileNameLabel)
            }
            rowStack.removeArrangedSubview(spacerView)
            rowStack.removeArrangedSubview(contentStack)
            rowStack.addArrangedSubview(contentStack)
            rowStack.addArrangedSubview(spacerView)
        } else {
            if contentStack.arrangedSubviews.first === imageContainer {
                contentStack.removeArrangedSubview(fileNameLabel)
                contentStack.removeArrangedSubview(imageContainer)
                contentStack.addArrangedSubview(fileNameLabel)
                contentStack.addArrangedSubview(imageContainer)
            }
            rowStack.removeArrangedSubview(spacerView)
            rowStack.removeArrangedSubview(contentStack)
            rowStack.addArrangedSubview(spacerView)
            rowStack.addArrangedSubview(contentStack)
        }

        fileNameLabel.isHidden = fileNameLabel.text?.isEmpty ?? true
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
            fileNameLabel.lineBreakMode = .byCharWrapping
        }
    }
}
