//
//  MediaPreviewItemViewController.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import AVFoundation

final class MediaPreviewItemViewController: UIViewController {
    private let item: PostMediaItem
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
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
        view.addSubview(imageView)
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.image = item.thumbnail
        
        if item.isVideo, let data = item.data {
            let ext = item.fileName?.split(separator: ".").last.map(String.init) ?? "mp4"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".\(ext)")
            do {
                try data.write(to: tempURL)
                let player = AVPlayer(url: tempURL)
                let layer = AVPlayerLayer(player: player)
                layer.frame = view.bounds
                layer.videoGravity = .resizeAspect
                view.layer.insertSublayer(layer, above: imageView.layer)
                self.player = player
                self.playerLayer = layer
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(togglePlay))
                view.addGestureRecognizer(tap)
            } catch {
                // fallback: image only
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
    
    @objc private func togglePlay() {
        guard let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
}
