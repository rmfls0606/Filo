//
//  UIImageView+Extension.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import UIKit
import Kingfisher

enum RequestModifier{
    static var modifer: AnyModifier{
        AnyModifier { request in
            var request = request
            request.setValue(NetworkConfig.apiKey, forHTTPHeaderField: "SeSACKey")
            request.setValue(NetworkConfig.authorization, forHTTPHeaderField: "Authorization") //임시
            
            return request
        }
    }
}

extension UIImageView{
    private var kfTargetSize: CGSize {
        let size = bounds.size == .zero ? frame.size : bounds.size
        return size == .zero ? CGSize(width: 200, height: 200) : size
    }

    private func kfOptions(withFade: Bool) -> KingfisherOptionsInfo {
        let processor = DownsamplingImageProcessor(size: kfTargetSize)
        var options: KingfisherOptionsInfo = [
            .scaleFactor(UIScreen.main.scale),
            .processor(processor),
            .cacheOriginalImage,
            .requestModifier(RequestModifier.modifer)
        ]
        if withFade {
            options.append(.transition(.fade(0.3)))
        } else {
            options.append(.keepCurrentImageWhileLoading)
        }
        return options
    }

    func setKFImage(urlString: String){
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }
        let options = kfOptions(withFade: true)

        let resource = KF.ImageResource(downloadURL: url, cacheKey: urlString)
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options)
    }

    func setKFImage(urlString: String, completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?){
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }
        let options = kfOptions(withFade: true)

        let resource = KF.ImageResource(downloadURL: url, cacheKey: urlString)
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options) { result in
            completion?(result)
        }
    }
    
    func setKFImageNoFade(urlString: String) {
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }
        let options = kfOptions(withFade: false)

        let resource = KF.ImageResource(downloadURL: url, cacheKey: urlString)
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options)
    }
    
    func setKFImageNoFade(urlString: String, completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) {
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }
        let options = kfOptions(withFade: false)

        let resource = KF.ImageResource(downloadURL: url, cacheKey: urlString)
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options) { result in
            completion?(result)
        }
    }

    func setKFAbsoluteImage(url: URL, fade: Bool = true, completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        let options = kfOptions(withFade: fade)
        let resource = KF.ImageResource(downloadURL: url, cacheKey: url.absoluteString)
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options) { result in
            completion?(result)
        }
    }
}
