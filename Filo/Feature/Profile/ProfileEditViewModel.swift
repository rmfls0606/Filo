//
//  ProfileEditViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation
import RxSwift
import RxCocoa

final class ProfileEditViewModel: ViewModelType {
    struct Input {
        let viewWillAppear: Observable<Void>
        let imageData: Observable<Data?>
        let nickText: Observable<String>
        let nameText: Observable<String>
        let introText: Observable<String>
        let phoneText: Observable<String>
        let hashTagsText: Observable<String>
        let saveTap: Observable<Void>
    }
    
    struct Output {
        let profileItem: Driver<MyInfoResponseDTO?>
        let saveEnabled: Driver<Bool>
        let saveSuccess: Signal<Void>
        let networkError: Signal<NetworkError>
    }
    
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let profileRelay = BehaviorRelay<MyInfoResponseDTO?>(value: nil)
        let errorRelay = PublishRelay<NetworkError>()
        let successRelay = PublishRelay<Void>()
        
        let imageDataRelay = BehaviorRelay<Data?>(value: nil)
        let nickRelay = BehaviorRelay<String>(value: "")
        let nameRelay = BehaviorRelay<String>(value: "")
        let introRelay = BehaviorRelay<String>(value: "")
        let phoneRelay = BehaviorRelay<String>(value: "")
        let hashTagsRelay = BehaviorRelay<String>(value: "")
        
        input.imageData
            .bind(to: imageDataRelay)
            .disposed(by: disposeBag)
        input.nickText
            .bind(to: nickRelay)
            .disposed(by: disposeBag)
        input.nameText
            .bind(to: nameRelay)
            .disposed(by: disposeBag)
        input.introText
            .bind(to: introRelay)
            .disposed(by: disposeBag)
        input.phoneText
            .bind(to: phoneRelay)
            .disposed(by: disposeBag)
        input.hashTagsText
            .bind(to: hashTagsRelay)
            .disposed(by: disposeBag)
        
        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                Task {
                    do {
                        let dto: MyInfoResponseDTO = try await self.service.request(UserRouter.getProfile)
                        profileRelay.accept(dto)
                        nickRelay.accept(dto.nick)
                        nameRelay.accept(dto.name ?? "")
                        introRelay.accept(dto.introduction ?? "")
                        phoneRelay.accept(dto.phoneNum ?? "")
                        let tagText = dto.hashTags.map { "#\($0)" }.joined(separator: " ")
                        hashTagsRelay.accept(tagText)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        let saveEnabled = Observable
            .combineLatest(nickRelay, nameRelay, introRelay, phoneRelay, hashTagsRelay)
            .map { nick, _, _, _, _ in
                return !nick.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .distinctUntilChanged()
        
        input.saveTap
            .withLatestFrom(Observable.combineLatest(profileRelay, imageDataRelay, nickRelay, nameRelay, introRelay, phoneRelay, hashTagsRelay))
            .subscribe(onNext: { [weak self] profile, imageData, nick, name, intro, phone, tagsText in
                guard let self else { return }
                let trimmedNick = nick.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNick.isEmpty else { return }
                
                Task {
                    do {
                        let profileImagePath: String
                        if let imageData {
                            let fileName = "profile_\(UUID().uuidString).jpg"
                            let file = MultipartFile(data: imageData,
                                                     name: "profile",
                                                     fileName: fileName,
                                                     mimeType: "image/jpeg")
                            let dto: ProfileImageResponseDTO = try await self.service.upload(
                                UserRouter.image(profile: ""),
                                files: [file]
                            )
                            profileImagePath = dto.profileImage
                        } else {
                            profileImagePath = profile?.profileImage ?? ""
                        }
                        
                        let hashTags = Self.parseHashTags(tagsText)
                        _ = try await self.service.request(
                            UserRouter.putProfile(
                                nick: trimmedNick,
                                name: name,
                                introduction: intro,
                                phoneNum: phone,
                                profileImage: profileImagePath,
                                hashTags: hashTags
                            )
                        ) as MyInfoResponseDTO
                        
                        successRelay.accept(())
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return Output(
            profileItem: profileRelay.asDriver(onErrorDriveWith: .empty()),
            saveEnabled: saveEnabled.asDriver(onErrorJustReturn: false),
            saveSuccess: successRelay.asSignal(),
            networkError: errorRelay.asSignal()
        )
    }
}

private extension ProfileEditViewModel {
    static func parseHashTags(_ text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",# ")
        let parts = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts
    }
}
