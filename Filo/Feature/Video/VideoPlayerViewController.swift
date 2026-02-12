import UIKit
import AVFoundation
import SnapKit
import RxSwift
import RxCocoa

final class VideoPlayerViewController: BaseViewController, UIGestureRecognizerDelegate {
    override var prefersCustomTabBarHidden: Bool { true }
    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        isExpandedLandscape ? .landscapeRight : .portrait
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        isExpandedLandscape ? .landscapeRight : .portrait
    }
    private let videoId: String
    private let viewModel: VideoPlayerViewModel
    private let disposeBag = DisposeBag()
    private let likeTapRelay = PublishRelay<Void>()
    private let videoTitleText: String
    private let videoCreatedAtText: String
    private let viewCount: Int

    private var player: AVPlayer?
    private let playerRenderView = PlayerRenderView()
    private var timeObserverToken: Any?
    private var subtitleCues: [VideoPlayerViewModel.SubtitleCue] = []
    private var currentQualities: [VideoQualityDTO] = []
    private var currentSubtitles: [VideoSubtitleDTO] = []
    private var currentMasterStreamURL: String?
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var lastRequestedURLString: String?
    private var retryWithHeaderAssetUsed = false
    private var retryWithQualityURLUsed = false
    private var isExpandedLandscape = false
    private var isScrubbing = false
    private var playbackRate: Float = 1.0
    private var areOverlayControlsHidden = false
    private var overlayAutoHideWorkItem: DispatchWorkItem?
    private var isLiked = false
    private var likeCount = 0
    private var likeRequestId = 0
    private var latestLikeRequestId = 0

    private let playerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.clipsToBounds = true
        return view
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .Pretendard.body2
        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private let videoTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray15.color
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let videoMetaLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 1
        return label
    }()

    private let settingsButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var imageConfig = UIImage.SymbolConfiguration(scale: .medium)
        config.preferredSymbolConfigurationForImage = imageConfig
        config.image = UIImage(systemName: "gearshape.fill")
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let expandButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var imageConfig = UIImage.SymbolConfiguration(scale: .medium)
        config.preferredSymbolConfigurationForImage = imageConfig
        config.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let button = UIButton(configuration: config)
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        return view
    }()
    
    private lazy var playerTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    private let controlsContainerView = UIView()

    private let playPauseButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "pause.fill")
        config.baseForegroundColor = .white
        return UIButton(configuration: config)
    }()

    private let rewindButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "gobackward.10")
        config.baseForegroundColor = .white
        return UIButton(configuration: config)
    }()

    private let forwardButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "goforward.10")
        config.baseForegroundColor = .white
        return UIButton(configuration: config)
    }()

    private let progressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        return slider
    }()

    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .Pretendard.caption1
        label.text = "00:00"
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .Pretendard.caption1
        label.text = "00:00"
        return label
    }()

    private let likeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var imageConfig = UIImage.SymbolConfiguration(scale: .medium)
        config.preferredSymbolConfigurationForImage = imageConfig
        config.image = UIImage(systemName: "heart")
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let button = UIButton(configuration: config)
        return button
    }()

    init(video: VideoResponseDTO) {
        self.videoId = video.videoId
        self.viewModel = VideoPlayerViewModel(videoId: video.videoId)
        self.videoTitleText = video.title
        self.videoCreatedAtText = video.createdAt
        self.viewCount = video.viewCount
        self.likeCount = LikeStore.shared.likeCount(id: video.videoId) ?? video.likeCount
        self.isLiked = LikeStore.shared.isLiked(id: video.videoId) || video.isLiked
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            stopPlayback()
        }
    }

    @MainActor
    deinit {
        stopPlayback()
        NotificationCenter.default.removeObserver(self)
    }

    override func configureHierarchy() {
        view.addSubview(playerContainerView)
        view.addSubview(subtitleLabel)
        view.addSubview(controlsContainerView)
        view.addSubview(settingsButton)
        view.addSubview(loadingIndicator)
        view.addSubview(videoTitleLabel)
        view.addSubview(videoMetaLabel)

        playerContainerView.addSubview(playerRenderView)
        playerContainerView.addGestureRecognizer(playerTapGesture)
        playerContainerView.addSubview(playPauseButton)
        playerContainerView.addSubview(rewindButton)
        playerContainerView.addSubview(forwardButton)
        playerContainerView.addSubview(likeButton)
        controlsContainerView.addSubview(progressSlider)
        controlsContainerView.addSubview(currentTimeLabel)
        controlsContainerView.addSubview(durationLabel)
        controlsContainerView.addSubview(expandButton)
    }

    override func configureLayout() {
        applyPlayerLayout(isLandscape: false)

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(playerContainerView).inset(16)
            make.bottom.equalTo(playerContainerView).inset(20)
        }

        controlsContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(playerContainerView.safeAreaLayoutGuide).inset(12)
            make.bottom.equalTo(playerContainerView.safeAreaLayoutGuide).inset(8)
            make.height.equalTo(62)
        }

        playPauseButton.snp.makeConstraints { make in
            make.center.equalTo(playerContainerView)
            make.size.equalTo(44)
        }

        rewindButton.snp.makeConstraints { make in
            make.trailing.equalTo(playPauseButton.snp.leading).offset(-20)
            make.centerY.equalTo(playPauseButton)
            make.size.equalTo(38)
        }

        forwardButton.snp.makeConstraints { make in
            make.leading.equalTo(playPauseButton.snp.trailing).offset(20)
            make.centerY.equalTo(playPauseButton)
            make.size.equalTo(38)
        }

        currentTimeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(8)
        }

        durationLabel.snp.makeConstraints { make in
            make.trailing.equalTo(expandButton.snp.leading).offset(-8)
            make.bottom.equalToSuperview().inset(8)
        }

        progressSlider.snp.makeConstraints { make in
            make.leading.equalTo(currentTimeLabel.snp.trailing).offset(8)
            make.trailing.equalTo(durationLabel.snp.leading).offset(-8)
            make.centerY.equalTo(currentTimeLabel)
        }
        
        expandButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalTo(currentTimeLabel)
        }

        likeButton.snp.makeConstraints { make in
            make.leading.equalTo(playerContainerView.safeAreaLayoutGuide).inset(8)
            make.top.equalTo(playerContainerView.safeAreaLayoutGuide).inset(8)
        }

        settingsButton.snp.makeConstraints { make in
            make.trailing.equalTo(playerContainerView.safeAreaLayoutGuide).inset(8)
            make.top.equalTo(playerContainerView.safeAreaLayoutGuide).inset(8)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(playerContainerView)
        }

        playerRenderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        videoTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(playerContainerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        videoMetaLabel.snp.makeConstraints { make in
            make.top.equalTo(videoTitleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    override func configureView() {
        navigationItem.title = "VIDEO PLAYER"
        playerRenderView.backgroundColor = .black
        progressSlider.minimumTrackTintColor = .systemRed
        progressSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.35)
        progressSlider.setThumbImage(circleThumbImage(diameter: 10, color: .systemRed), for: .normal)
        videoTitleLabel.text = videoTitleText
        LikeStore.shared.setLiked(id: videoId, liked: isLiked, count: likeCount)
        updateLikeButtonAppearance()
        updateVideoMetaText()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerItemFailed(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: nil
        )
    }

    override func configureBind() {
        let selectedSubtitleRelay = PublishRelay<String?>()
        let input = VideoPlayerViewModel.Input(
            viewDidLoad: Observable.just(()),
            selectedSubtitleURL: selectedSubtitleRelay.asObservable()
        )
        let output = viewModel.transform(input: input)

        settingsButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentSettingsSheet(selectedSubtitleRelay: selectedSubtitleRelay)
            }
            .disposed(by: disposeBag)

        playPauseButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.togglePlayPause()
            }
            .disposed(by: disposeBag)

        rewindButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.seekBy(seconds: -10)
            }
            .disposed(by: disposeBag)

        forwardButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.seekBy(seconds: 10)
            }
            .disposed(by: disposeBag)

        progressSlider.rx.controlEvent(.touchDown)
            .bind(with: self) { owner, _ in
                owner.isScrubbing = true
            }
            .disposed(by: disposeBag)

        progressSlider.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .bind(with: self) { owner, _ in
                owner.finishScrubbingAndSeek()
            }
            .disposed(by: disposeBag)

        likeButton.rx.tap
            .bind(to: likeTapRelay)
            .disposed(by: disposeBag)
        
        expandButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.toggleExpandedPlayerOrientation()
            }
            .disposed(by: disposeBag)
        
        playerTapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.toggleOverlayControls()
            }
            .disposed(by: disposeBag)

        output.isLoading
            .drive(with: self) { owner, isLoading in
                isLoading ? owner.loadingIndicator.startAnimating() : owner.loadingIndicator.stopAnimating()
            }
            .disposed(by: disposeBag)

        output.qualities
            .drive(with: self) { owner, qualities in
                owner.currentQualities = qualities
            }
            .disposed(by: disposeBag)

        output.masterStreamURL
            .drive(with: self) { owner, url in
                owner.currentMasterStreamURL = url
            }
            .disposed(by: disposeBag)

        output.subtitleCues
            .drive(with: self) { owner, cues in
                owner.subtitleCues = cues
                owner.subtitleLabel.isHidden = cues.isEmpty
            }
            .disposed(by: disposeBag)

        output.subtitles
            .drive(with: self) { owner, subtitles in
                owner.currentSubtitles = subtitles
            }
            .disposed(by: disposeBag)

        likeTapRelay
            .asObservable()
            .compactMap { [weak self] _ -> (desiredLiked: Bool, requestId: Int, prevLiked: Bool, prevCount: Int, optimisticCount: Int)? in
                guard let self else { return nil }
                let prevLiked = self.isLiked
                let prevCount = self.likeCount
                let desiredLiked = !prevLiked
                let optimisticCount = max(0, prevCount + (desiredLiked ? 1 : -1))
                self.isLiked = desiredLiked
                self.likeCount = optimisticCount
                LikeStore.shared.setLiked(id: self.videoId, liked: desiredLiked, count: optimisticCount)
                self.updateLikeButtonAppearance()
                self.updateVideoMetaText()
                self.likeRequestId += 1
                self.latestLikeRequestId = self.likeRequestId
                return (desiredLiked, self.likeRequestId, prevLiked, prevCount, optimisticCount)
            }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] payload -> Observable<(liked: Bool, resolvedCount: Int)> in
                guard let self else { return .empty() }
                let desiredLiked = payload.desiredLiked
                let requestId = payload.requestId
                let prevLiked = payload.prevLiked
                let prevCount = payload.prevCount
                let optimisticCount = payload.optimisticCount

                return Observable<Bool>.create { observer in
                    Task {
                        do {
                            let likeStatus = try await self.requestVideoLike(desiredLiked: desiredLiked)
                            observer.onNext(likeStatus)
                            observer.onCompleted()
                        } catch {
                            observer.onError(error)
                        }
                    }
                    return Disposables.create()
                }
                .flatMap { [weak self] likedNow -> Observable<(liked: Bool, resolvedCount: Int)> in
                    guard let self else { return .empty() }
                    guard self.latestLikeRequestId == requestId else { return .empty() }
                    let resolvedCount = (likedNow == desiredLiked)
                        ? optimisticCount
                        : max(0, prevCount + (likedNow ? 1 : -1))
                    return .just((likedNow, resolvedCount))
                }
                .catch { [weak self] error in
                    guard let self else { return .empty() }
                    guard self.latestLikeRequestId == requestId else { return .empty() }
                    self.showAlert(title: "오류", message: (error as? NetworkError)?.errorDescription ?? "좋아요 처리에 실패했습니다.")
                    return .just((prevLiked, prevCount))
                }
            }
            .bind(with: self) { owner, result in
                owner.isLiked = result.liked
                owner.likeCount = result.resolvedCount
                LikeStore.shared.setLiked(id: owner.videoId, liked: result.liked, count: result.resolvedCount)
                owner.updateLikeButtonAppearance()
                owner.updateVideoMetaText()
            }
            .disposed(by: disposeBag)

        output.playRequest
            .emit(with: self) { owner, request in
                owner.play(urlString: request.urlString, preservingCurrentPosition: request.preservingCurrentPosition)
                owner.scheduleOverlayAutoHideIfNeeded()
            }
            .disposed(by: disposeBag)

        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
    }

    private func play(urlString: String, preservingCurrentPosition: Bool, useHeaderAsset: Bool = false) {
        guard !urlString.isEmpty else {
            showAlert(title: "오류", message: "재생 가능한 스트리밍 URL이 없습니다.")
            loadingIndicator.stopAnimating()
            return
        }
        guard let url = absoluteURL(from: urlString) else {
            showAlert(title: "오류", message: "스트리밍 URL 형식이 올바르지 않습니다.")
            loadingIndicator.stopAnimating()
            return
        }
        let previousTime = preservingCurrentPosition ? player?.currentTime() : nil
        let wasPlaying = preservingCurrentPosition ? (player?.rate ?? 0) > 0 : true

        if !preservingCurrentPosition {
            retryWithHeaderAssetUsed = false
            retryWithQualityURLUsed = false
        }
        lastRequestedURLString = urlString

        let item: AVPlayerItem
        if useHeaderAsset {
            let headers: [String: String] = [
                "Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey
            ]
            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
            item = AVPlayerItem(asset: asset)
        } else {
            item = AVPlayerItem(url: url)
        }
        observePlayerItemStatus(item)
        if player == nil {
            let newPlayer = AVPlayer(playerItem: item)
            player = newPlayer
            playerRenderView.player = newPlayer
            addSubtitleObserver()
            newPlayer.playImmediately(atRate: playbackRate)
            updatePlayPauseIcon(isPlaying: true)
        } else if let player {
            player.replaceCurrentItem(with: item)
            if let previousTime {
                player.seek(to: previousTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak player] _ in
                    if wasPlaying {
                        player?.playImmediately(atRate: self.playbackRate)
                    }
                }
            } else if wasPlaying {
                player.playImmediately(atRate: playbackRate)
            }
            updatePlayPauseIcon(isPlaying: wasPlaying)
        }
        loadingIndicator.stopAnimating()
    }

    private func presentQualitySheet() {
        let alert = UIAlertController(title: "화질 선택", message: nil, preferredStyle: .actionSheet)

        let autoAction = UIAlertAction(title: "Auto", style: .default) { [weak self] _ in
            self?.applyQualitySelection(nil)
        }
        alert.addAction(autoAction)

        currentQualities.forEach { quality in
            alert.addAction(UIAlertAction(title: quality.quality, style: .default) { [weak self] _ in
                self?.applyQualitySelection(quality)
            })
        }
        present(alert, animated: true)
    }

    private func presentSubtitleSheet(selectedSubtitleRelay: PublishRelay<String?>) {
        let alert = UIAlertController(title: "자막 선택", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "없음", style: .default) { _ in
            selectedSubtitleRelay.accept(nil)
        })
        currentSubtitles.forEach { subtitle in
            alert.addAction(UIAlertAction(title: subtitle.name, style: .default) { _ in
                selectedSubtitleRelay.accept(subtitle.url)
            })
        }
        present(alert, animated: true)
    }

    private func presentSettingsSheet(selectedSubtitleRelay: PublishRelay<String?>) {
        let alert = UIAlertController(title: "재생 설정", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "화질", style: .default) { [weak self] _ in
            self?.presentQualitySheet()
        })
        alert.addAction(UIAlertAction(title: "재생 속도", style: .default) { [weak self] _ in
            self?.presentSpeedSheet()
        })
        alert.addAction(UIAlertAction(title: "자막", style: .default) { [weak self] _ in
            self?.presentSubtitleSheet(selectedSubtitleRelay: selectedSubtitleRelay)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func applyQualitySelection(_ quality: VideoQualityDTO?) {
        guard let player else { return }

        if let currentItem = player.currentItem, !(currentMasterStreamURL?.isEmpty ?? true) {
            let bitrate = quality.flatMap { bitrateForQualityLabel($0.quality) } ?? 0
            currentItem.preferredPeakBitRate = bitrate
            return
        }

        if let quality {
            play(urlString: quality.url, preservingCurrentPosition: true)
        }
    }

    private func bitrateForQualityLabel(_ label: String) -> Double? {
        let digits = label.filter { $0.isNumber }
        guard let height = Int(digits) else { return nil }
        switch height {
        case ..<360: return 400_000
        case 360..<480: return 800_000
        case 480..<540: return 1_400_000
        case 540..<720: return 2_300_000
        case 720..<1080: return 4_500_000
        case 1080..<1440: return 8_000_000
        case 1440..<2160: return 16_000_000
        default: return 30_000_000
        }
    }

    private func addSubtitleObserver() {
        guard timeObserverToken == nil, let player else { return }
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = time.seconds
            guard seconds.isFinite else { return }

            if let cue = self.subtitleCues.first(where: { seconds >= $0.start && seconds <= $0.end }) {
                self.subtitleLabel.text = "  \(cue.text)  "
                self.subtitleLabel.isHidden = false
            } else {
                self.subtitleLabel.text = nil
                self.subtitleLabel.isHidden = true
            }

            self.updateProgressUI(currentSeconds: seconds)
        }
    }

    private func absoluteURL(from pathOrURL: String) -> URL? {
        let trimmed = pathOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        let relative = trimmed.hasPrefix("/") ? trimmed : "/" + trimmed
        return URL(string: NetworkConfig.baseURL + relative)
    }

    private func observePlayerItemStatus(_ item: AVPlayerItem) {
        playerItemStatusObservation = item.observe(\.status, options: [.new, .initial]) { item, _ in
            guard item.status == .failed else { return }
            DispatchQueue.main.async { [weak self] in
                self?.retryPlaybackIfPossible()
            }
        }
    }

    @objc
    private func handlePlayerItemFailed(_ notification: Notification) {
        retryPlaybackIfPossible()
    }

    private func retryPlaybackIfPossible() {
        guard let lastRequestedURLString else { return }

        if !retryWithHeaderAssetUsed {
            retryWithHeaderAssetUsed = true
            play(urlString: lastRequestedURLString, preservingCurrentPosition: true, useHeaderAsset: true)
            return
        }

        if !retryWithQualityURLUsed,
           let fallbackURL = currentQualities.first(where: { !$0.url.isEmpty })?.url,
           fallbackURL != lastRequestedURLString {
            retryWithQualityURLUsed = true
            play(urlString: fallbackURL, preservingCurrentPosition: true)
        }
    }
    
    private func toggleExpandedPlayerOrientation() {
        isExpandedLandscape.toggle()
        setNeedsUpdateOfSupportedInterfaceOrientations()
        navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()

        if isExpandedLandscape {
            navigationController?.setNavigationBarHidden(true, animated: true)
            applyPlayerLayout(isLandscape: true)
            AppDelegate.orientationLock = .landscapeRight
            forceOrientation(.landscapeRight)
            expandButton.setImage(UIImage(systemName: "arrow.down.right.and.arrow.up.left"), for: .normal)
        } else {
            navigationController?.setNavigationBarHidden(false, animated: true)
            applyPlayerLayout(isLandscape: false)
            AppDelegate.orientationLock = .portrait
            forceOrientation(.portrait)
            expandButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        }
    }

    private func forceOrientation(_ orientation: UIInterfaceOrientation) {
        if #available(iOS 16.0, *),
           let scene = view.window?.windowScene {
            let mask: UIInterfaceOrientationMask = orientation.isLandscape ? .landscapeRight : .portrait
            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
            scene.requestGeometryUpdate(preferences)
            UIViewController.attemptRotationToDeviceOrientation()
        } else {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private func stopPlayback() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        AppDelegate.orientationLock = .portrait
        isExpandedLandscape = false
        cancelOverlayAutoHide()
        player?.pause()
        playerItemStatusObservation = nil

        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        player?.replaceCurrentItem(with: nil)
        playerRenderView.player = nil
        player = nil
        updatePlayPauseIcon(isPlaying: false)
        progressSlider.value = 0
        currentTimeLabel.text = "00:00"
        durationLabel.text = "00:00"
        setOverlayControlsHidden(false, animated: false)
    }

    private func applyPlayerLayout(isLandscape: Bool) {
        playerContainerView.snp.remakeConstraints { make in
            if isLandscape {
                make.edges.equalToSuperview()
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
                make.horizontalEdges.equalToSuperview()
                make.height.equalTo(playerContainerView.snp.width).multipliedBy(9.0 / 16.0)
            }
        }
        view.layoutIfNeeded()
    }

    private func togglePlayPause() {
        guard let player else { return }
        if player.rate == 0 {
            player.playImmediately(atRate: playbackRate)
            updatePlayPauseIcon(isPlaying: true)
            scheduleOverlayAutoHideIfNeeded()
        } else {
            player.pause()
            updatePlayPauseIcon(isPlaying: false)
            cancelOverlayAutoHide()
        }
    }

    private func seekBy(seconds: Double) {
        guard let player else { return }
        let current = player.currentTime().seconds
        guard current.isFinite else { return }
        let target = max(0, current + seconds)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    private func presentSpeedSheet() {
        let alert = UIAlertController(title: "재생 속도", message: nil, preferredStyle: .actionSheet)
        [0.5, 1.0, 1.25, 1.5, 2.0].forEach { speed in
            let title = String(format: "%.2gx", speed)
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.setPlaybackRate(Float(speed))
            })
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if let player, player.rate > 0 {
            player.rate = rate
        }
    }

    private func finishScrubbingAndSeek() {
        guard let player else {
            isScrubbing = false
            return
        }
        let durationSeconds = player.currentItem?.duration.seconds ?? 0
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            isScrubbing = false
            return
        }
        let target = Double(progressSlider.value) * durationSeconds
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
        isScrubbing = false
        scheduleOverlayAutoHideIfNeeded()
    }

    private func updateProgressUI(currentSeconds: Double) {
        guard let player else { return }
        let durationSeconds = player.currentItem?.duration.seconds ?? 0
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            currentTimeLabel.text = formatTime(currentSeconds)
            durationLabel.text = "00:00"
            return
        }
        currentTimeLabel.text = formatTime(currentSeconds)
        durationLabel.text = formatTime(durationSeconds)
        if !isScrubbing {
            progressSlider.value = Float(currentSeconds / durationSeconds)
        }
    }

    private func updatePlayPauseIcon(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.configuration?.image = UIImage(systemName: imageName)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
    
    private func toggleOverlayControls() {
        setOverlayControlsHidden(!areOverlayControlsHidden, animated: true)
    }
    
    private func setOverlayControlsHidden(_ hidden: Bool, animated: Bool) {
        areOverlayControlsHidden = hidden
        let targetAlpha: CGFloat = hidden ? 0 : 1
        let changes = {
            self.controlsContainerView.alpha = targetAlpha
            self.settingsButton.alpha = targetAlpha
            self.expandButton.alpha = targetAlpha
            self.likeButton.alpha = targetAlpha
            self.subtitleLabel.alpha = targetAlpha
            self.playPauseButton.alpha = targetAlpha
            self.rewindButton.alpha = targetAlpha
            self.forwardButton.alpha = targetAlpha
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }

        if hidden {
            cancelOverlayAutoHide()
        } else {
            scheduleOverlayAutoHideIfNeeded()
        }
    }

    private func scheduleOverlayAutoHideIfNeeded() {
        cancelOverlayAutoHide()
        guard let player, player.rate > 0, !areOverlayControlsHidden else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.setOverlayControlsHidden(true, animated: true)
        }
        overlayAutoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
    }

    private func cancelOverlayAutoHide() {
        overlayAutoHideWorkItem?.cancel()
        overlayAutoHideWorkItem = nil
    }

    private func updateLikeButtonAppearance() {
        likeButton.configuration?.image = UIImage(systemName: isLiked ? "heart.fill" : "heart")
        likeButton.configuration?.baseForegroundColor = isLiked ? .systemRed : .white
    }

    private func updateVideoMetaText() {
        let relative = relativeCreatedAtText(from: videoCreatedAtText)
        videoMetaLabel.text = "조회수 \(viewCount)회 좋아요 \(likeCount) \(relative)"
    }

    private func relativeCreatedAtText(from raw: String) -> String {
        guard let date = parseDate(raw) else { return "방금 전" }
        let interval = max(0, Int(Date().timeIntervalSince(date)))

        let minute = 60
        let hour = 3600
        let day = 86_400
        let month = 2_592_000
        let year = 31_536_000

        switch interval {
        case 0..<minute: return "방금 전"
        case minute..<hour: return "\(interval / minute)분 전"
        case hour..<day: return "\(interval / hour)시간 전"
        case day..<month: return "\(interval / day)일 전"
        case month..<year: return "\(interval / month)개월 전"
        default: return "\(interval / year)년 전"
        }
    }

    private func parseDate(_ raw: String) -> Date? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let iso8601WithFractional = ISO8601DateFormatter()
        iso8601WithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601WithFractional.date(from: text) {
            return date
        }

        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime]
        if let date = iso8601.date(from: text) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        if let date = formatter.date(from: text) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        if let date = formatter.date(from: text) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: text)
    }

    private func requestVideoLike(desiredLiked: Bool) async throws -> Bool {
        let dto: VideoLikeStatus = try await NetworkManager.shared.request(
            VideoRouter.like(videoId: videoId, likeStatus: desiredLiked)
        )
        return dto.likeStatus
    }

    private func circleThumbImage(diameter: CGFloat, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { context in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === playerTapGesture else { return true }
        guard let touchedView = touch.view else { return true }

        if touchedView is UIControl { return false }
        if touchedView.isDescendant(of: controlsContainerView) { return false }
        if touchedView.isDescendant(of: likeButton) { return false }
        if touchedView.isDescendant(of: settingsButton) { return false }
        if touchedView.isDescendant(of: subtitleLabel) { return false }

        return true
    }

}

final class PlayerRenderView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer {
        guard let playerLayer = layer as? AVPlayerLayer else {
            return AVPlayerLayer()
        }
        return playerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set {
            playerLayer.player = newValue
            playerLayer.videoGravity = .resizeAspect
        }
    }
}
