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
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        view.color = .white
        return view
    }()
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playbackObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    
    private var currentURL: String?
    private var thumbnailRequestId = UUID()
    
    var isVideo: Bool = false
    
    override func configureHierarchy() {
        contentView.addSubview(imageView)
        contentView.addSubview(playIconView)
        contentView.addSubview(loadingIndicator)
    }
    
    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func configureView() {
        contentView.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(togglePlayback))
        contentView.addGestureRecognizer(tap)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.alpha = 1.0
        playIconView.isHidden = true
        currentURL = nil
        thumbnailRequestId = UUID()
        stopPlayback()
        hideLoading()
    }
    
    func configure(urlString: String) {
        currentURL = urlString
        isVideo = isVideoURL(urlString)
        playIconView.isHidden = true
        if isVideo {
            if imageView.image == nil {
                imageView.backgroundColor = .black
            }
            imageView.backgroundColor = .black
            imageView.contentMode = .scaleAspectFill
            imageView.alpha = 1.0
            showLoading()
            generateVideoThumbnail(urlString: urlString)
        } else {
            imageView.backgroundColor = GrayStyle.gray90.color
            imageView.contentMode = .scaleAspectFill
            imageView.setKFImageNoFade(urlString: urlString)
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
    
    func startPlayback(muted: Bool = true) {
        guard isVideo, let urlString = currentURL, player == nil else { return }
        guard let asset = makeAuthorizedAsset(urlString: urlString) else { return }
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.isMuted = muted
        let layer = AVPlayerLayer(player: player)
        layer.frame = contentView.bounds
        layer.videoGravity = .resizeAspectFill
        contentView.layer.insertSublayer(layer, above: imageView.layer)
        self.player = player
        self.playerLayer = layer
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self?.hideLoading()
                    self?.imageView.alpha = 0.0
                } else if item.status == .failed {
                    self?.hideLoading()
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
        imageView.alpha = 1.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
    }
    
    func makeTransitionSnapshotView() -> UIView? {
        contentView.snapshotView(afterScreenUpdates: true)
    }
    
    private func showLoading() {
        loadingIndicator.startAnimating()
    }
    
    private func hideLoading() {
        loadingIndicator.stopAnimating()
    }
    
    @objc private func togglePlayback() {
        guard isVideo, let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
}
