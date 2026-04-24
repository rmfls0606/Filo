//
//  MediaPreviewItemViewController.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

final class MediaPreviewItemViewController: UIViewController, UIScrollViewDelegate {
    private let item: PostMediaItem
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let disposeBag = DisposeBag()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.minimumZoomScale = 1.0
        view.maximumZoomScale = 4.0
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .black
        return view
    }()
    
    init(item: PostMediaItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.image = item.thumbnail
        configureImageZoom()

        if item.isVideo {
            if let data = item.data {
                let ext = item.fileName?.split(separator: ".").last.map(String.init) ?? "mp4"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".\(ext)")
                do {
                    try data.write(to: tempURL)
                    setupPlayer(url: tempURL)
                } catch {
                    // fallback: image only
                }
            } else if let remotePath = item.remotePath {
                if let asset = makeAuthorizedAsset(path: remotePath) {
                    let playerItem = AVPlayerItem(asset: asset)
                    let player = AVPlayer(playerItem: playerItem)
                    setupPlayer(player: player)
                }
            }
        } else if let remotePath = item.remotePath {
            imageView.setKFImage(urlString: remotePath, targetSize: imageView.bounds.size)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            imageView.frame = scrollView.bounds
        }
        playerLayer?.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        player?.seek(to: .zero)
    }
    
    private func togglePlay() {
        guard let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    private func setupPlayer(url: URL) {
        let player = AVPlayer(url: url)
        setupPlayer(player: player)
    }

    private func setupPlayer(player: AVPlayer) {
        let layer = AVPlayerLayer(player: player)
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspect
        view.layer.insertSublayer(layer, above: scrollView.layer)
        self.player = player
        self.playerLayer = layer
        
        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        tap.rx.event
            .bind(with: self) { owner, _ in
                owner.togglePlay()
            }
            .disposed(by: disposeBag)
    }

    private func makeAuthorizedAsset(path: String) -> AVURLAsset? {
        guard let url = URL(string: NetworkConfig.baseURL + "/" + path) else { return nil }
        let headers = [
            "SeSACKey": NetworkConfig.apiKey,
            "Authorization": NetworkConfig.authorization
        ]
        return AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
    }

    private func configureImageZoom() {
        let doubleTap = UITapGestureRecognizer()
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        doubleTap.rx.event
            .bind(with: self) { owner, gesture in
                owner.handleDoubleTap(gesture)
            }
            .disposed(by: disposeBag)
    }
    
    private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }

        let targetScale = min(scrollView.maximumZoomScale, scrollView.minimumZoomScale * 2.5)
        let point = gesture.location(in: imageView)
        let size = CGSize(
            width: scrollView.bounds.width / targetScale,
            height: scrollView.bounds.height / targetScale
        )
        let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        item.isVideo ? nil : imageView
    }
}
