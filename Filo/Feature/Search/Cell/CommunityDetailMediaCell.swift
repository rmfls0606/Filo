//
//  CommunityDetailMediaCell.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit
import AVFoundation

final class CommunityDetailMediaCell: BaseCollectionViewCell {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = GrayStyle.gray90.color
        return view
    }()
    
    private let playIconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "play.circle.fill")
        view.tintColor = GrayStyle.gray90.color
        view.isHidden = true
        return view
    }()
    
    private var currentURL: String?
    private var thumbnailRequestId = UUID()
    
    override func configureHierarchy() {
        contentView.addSubview(imageView)
        contentView.addSubview(playIconView)
    }
    
    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }
    }
    
    override func configureView() {
        contentView.backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        playIconView.isHidden = true
        currentURL = nil
        thumbnailRequestId = UUID()
    }
    
    func configure(urlString: String) {
        currentURL = urlString
        let isVideo = isVideoURL(urlString)
        playIconView.isHidden = !isVideo
        if isVideo {
            imageView.image = UIImage(systemName: "photo")?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = GrayStyle.gray75.color
            imageView.contentMode = .scaleAspectFit
            generateVideoThumbnail(urlString: urlString)
        } else {
            imageView.contentMode = .scaleAspectFill
            imageView.setKFImage(urlString: urlString)
        }
    }
    
    private func isVideoURL(_ urlString: String) -> Bool {
        let ext = (urlString as NSString).pathExtension.lowercased()
        return ["mp4", "mov", "avi", "mkv", "wmv", "webm"].contains(ext)
    }
    
    private func makeAuthorizedAsset(urlString: String) -> AVURLAsset? {
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return nil }
        let headers = [
            "SeSACKey": NetworkConfig.apiKey,
            "Authorization": NetworkConfig.authorization
        ]
        return AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
    }
    
    private func generateVideoThumbnail(urlString: String) {
        guard let asset = makeAuthorizedAsset(urlString: urlString) else { return }
        let requestId = UUID()
        thumbnailRequestId = requestId
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
                DispatchQueue.main.async {
                    guard let self, self.thumbnailRequestId == requestId, self.currentURL == urlString else { return }
                    self.imageView.image = UIImage(systemName: "photo")?.withRenderingMode(.alwaysTemplate)
                    self.imageView.tintColor = GrayStyle.gray75.color
                    self.imageView.contentMode = .scaleAspectFit
                }
                return
            }
            let image = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                guard let self, self.thumbnailRequestId == requestId, self.currentURL == urlString else { return }
                self.imageView.image = image
                self.imageView.contentMode = .scaleAspectFill
            }
        }
    }
}
