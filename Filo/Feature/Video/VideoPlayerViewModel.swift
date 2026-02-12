import Foundation
import RxSwift
import RxCocoa

final class VideoPlayerViewModel: ViewModelType {
    struct SubtitleCue {
        let start: TimeInterval
        let end: TimeInterval
        let text: String
    }

    struct PlayRequest {
        let urlString: String
        let preservingCurrentPosition: Bool
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let selectedSubtitleURL: Observable<String?>
    }

    struct Output {
        let playRequest: Signal<PlayRequest>
        let qualities: Driver<[VideoQualityDTO]>
        let masterStreamURL: Driver<String>
        let subtitles: Driver<[VideoSubtitleDTO]>
        let subtitleCues: Driver<[SubtitleCue]>
        let isLoading: Driver<Bool>
        let networkError: Signal<NetworkError>
    }

    private let videoId: String
    private let disposeBag = DisposeBag()

    init(videoId: String) {
        self.videoId = videoId
    }

    func transform(input: Input) -> Output {
        let streamRelay = BehaviorRelay<StreamUrlResponseDTO?>(value: nil)
        let qualitiesRelay = BehaviorRelay<[VideoQualityDTO]>(value: [])
        let masterStreamURLRelay = BehaviorRelay<String>(value: "")
        let subtitlesRelay = BehaviorRelay<[VideoSubtitleDTO]>(value: [])
        let subtitleCuesRelay = BehaviorRelay<[SubtitleCue]>(value: [])
        let playRequestRelay = PublishRelay<PlayRequest>()
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let networkErrorRelay = PublishRelay<NetworkError>()

        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                isLoadingRelay.accept(true)
                Task {
                    do {
                        let dto: StreamUrlResponseDTO = try await NetworkManager.shared.request(
                            VideoRouter.stream(videoId: self.videoId)
                        )
                        streamRelay.accept(dto)
                        qualitiesRelay.accept(dto.qualities)
                        masterStreamURLRelay.accept(dto.streamURL)
                        subtitlesRelay.accept(dto.subtitles)
                        let playURL = dto.streamURL.isEmpty ? (dto.qualities.first?.url ?? "") : dto.streamURL
                        playRequestRelay.accept(PlayRequest(urlString: playURL, preservingCurrentPosition: false))

                        if let subtitle = dto.subtitles.first(where: { $0.isDefault }) ?? dto.subtitles.first {
                            do {
                                let cues = try await self.fetchAndParseSubtitle(urlString: subtitle.url)
                                subtitleCuesRelay.accept(cues)
                            } catch {
                                subtitleCuesRelay.accept([])
                            }
                        } else {
                            subtitleCuesRelay.accept([])
                        }

                        isLoadingRelay.accept(false)
                    } catch let error as NetworkError {
                        isLoadingRelay.accept(false)
                        networkErrorRelay.accept(error)
                    } catch {
                        isLoadingRelay.accept(false)
                        networkErrorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)

        input.selectedSubtitleURL
            .subscribe(onNext: { [weak self] selectedURL in
                guard let self else { return }
                if let selectedURL, !selectedURL.isEmpty {
                    Task {
                        do {
                            let cues = try await self.fetchAndParseSubtitle(urlString: selectedURL)
                            subtitleCuesRelay.accept(cues)
                        } catch {
                            subtitleCuesRelay.accept([])
                        }
                    }
                } else {
                    subtitleCuesRelay.accept([])
                }
            })
            .disposed(by: disposeBag)

        return Output(
            playRequest: playRequestRelay.asSignal(),
            qualities: qualitiesRelay.asDriver(),
            masterStreamURL: masterStreamURLRelay.asDriver(),
            subtitles: subtitlesRelay.asDriver(),
            subtitleCues: subtitleCuesRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            networkError: networkErrorRelay.asSignal()
        )
    }

    private func fetchAndParseSubtitle(urlString: String) async throws -> [SubtitleCue] {
        guard let url = absoluteURL(from: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(NetworkConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        request.setValue(NetworkConfig.authorization, forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        return parseSubtitleText(text)
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

    private func parseSubtitleText(_ text: String) -> [SubtitleCue] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = normalized.components(separatedBy: "\n\n")
        var cues: [SubtitleCue] = []

        for block in blocks {
            let lines = block
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !lines.isEmpty else { continue }

            guard let timeLineIndex = lines.firstIndex(where: { $0.contains("-->") }) else { continue }
            let timeLine = lines[timeLineIndex]
            let timeRange = timeLine.components(separatedBy: "-->")
            guard timeRange.count == 2 else { continue }

            let start = parseTimestamp(timeRange[0])
            let end = parseTimestamp(timeRange[1])
            guard let start, let end, end >= start else { continue }

            let subtitleLines = Array(lines[(timeLineIndex + 1)...])
            let text = subtitleLines.joined(separator: "\n")
            guard !text.isEmpty else { continue }

            cues.append(SubtitleCue(start: start, end: end, text: text))
        }

        return cues
    }

    private func parseTimestamp(_ raw: String) -> TimeInterval? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed
            .replacingOccurrences(of: ",", with: ".")
            .components(separatedBy: " ")
            .first ?? trimmed
        let parts = normalized.split(separator: ":")
        
        if parts.count == 3 {
            guard
                let hour = Double(parts[0]),
                let minute = Double(parts[1]),
                let second = Double(parts[2])
            else { return nil }
            return (hour * 3600) + (minute * 60) + second
        }
        
        if parts.count == 2 {
            guard
                let minute = Double(parts[0]),
                let second = Double(parts[1])
            else { return nil }
            return (minute * 60) + second
        }
        
        return nil
    }
}
