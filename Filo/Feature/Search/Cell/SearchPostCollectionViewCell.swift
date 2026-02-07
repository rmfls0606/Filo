//
//  SearchPostCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit
import AVFoundation

final class SearchPostCollectionViewCell: BaseCollectionViewCell {
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
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        view.color = .white
        return view
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray30.color
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()
    
    private var currentURL: String?
    private var thumbnailRequestId = UUID()
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var isVideoItem: Bool = false
    private var playbackObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?

    override func configureHierarchy() {
        contentView.addSubview(imageView)
        contentView.addSubview(playIconView)
        contentView.addSubview(loadingIndicator)
        contentView.addSubview(durationLabel)
    }

    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(6)
            make.bottom.equalToSuperview().inset(6)
            make.height.equalTo(16)
        }
    }

    override func configureView() {
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 1.0
        playIconView.isHidden = true
        loadingIndicator.stopAnimating()
        durationLabel.isHidden = true
        durationLabel.text = nil
        currentURL = nil
        thumbnailRequestId = UUID()
        stopPlayback()
    }

    func configure(item: PostSummaryResponseDTO) {
        guard let urlString = item.files.first else { return }
        currentURL = urlString
        let isVideo = isVideoURL(urlString)
        isVideoItem = isVideo
        playIconView.isHidden = !isVideo
        
        if isVideo {
            imageView.image = nil
            imageView.backgroundColor = .black
            imageView.contentMode = .scaleAspectFill
            imageView.alpha = 1.0
            loadingIndicator.startAnimating()
            generateVideoThumbnail(urlString: urlString)
            generateVideoDuration(urlString: urlString)
        } else {
            imageView.backgroundColor = GrayStyle.gray90.color
            imageView.setKFImage(urlString: urlString)
            imageView.contentMode = .scaleAspectFill
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
                    self.loadingIndicator.stopAnimating()
                    self.imageView.image = nil
                    self.imageView.backgroundColor = .black
                    self.imageView.contentMode = .scaleAspectFill
                }
                return
            }
            let image = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                guard let self, self.thumbnailRequestId == requestId, self.currentURL == urlString else { return }
                self.imageView.image = image
                self.imageView.contentMode = .scaleAspectFill
                self.loadingIndicator.stopAnimating()
            }
        }
    }
    
    private func generateVideoDuration(urlString: String) {
        guard let asset = makeAuthorizedAsset(urlString: urlString) else { return }
        let requestId = thumbnailRequestId
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let duration = CMTimeGetSeconds(asset.duration)
            guard duration.isFinite else { return }
            let text = Self.formatDuration(duration)
            DispatchQueue.main.async {
                guard let self, self.thumbnailRequestId == requestId, self.currentURL == urlString else { return }
                self.durationLabel.text = " \(text) "
                self.durationLabel.isHidden = false
            }
        }
    }
    
    private static func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    func isVideoCell() -> Bool {
        isVideoItem
    }
    
    func startPlayback() {
        guard isVideoItem, player == nil, let urlString = currentURL else { return }
        guard let asset = makeAuthorizedAsset(urlString: urlString) else { return }
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        let layer = AVPlayerLayer(player: player)
        layer.frame = contentView.bounds
        layer.videoGravity = .resizeAspectFill
        contentView.layer.insertSublayer(layer, above: imageView.layer)
        self.player = player
        self.playerLayer = layer
        playIconView.isHidden = true
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self?.loadingIndicator.stopAnimating()
                    UIView.animate(withDuration: 0.15) {
                        self?.imageView.alpha = 0.0
                    }
                } else if item.status == .failed {
                    self?.loadingIndicator.stopAnimating()
                }
            }
        }
        playbackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        player.play()
    }
    
    func stopPlayback() {
        player?.pause()
        statusObservation = nil
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackObserver = nil
        }
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        playIconView.isHidden = !isVideoItem
        imageView.alpha = 1.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
    }
}
