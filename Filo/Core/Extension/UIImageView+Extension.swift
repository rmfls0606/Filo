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
    func setKFImage(urlString: String){
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }

        let targetSize = bounds.size == .zero ? frame.size : bounds.size
        let processor = DownsamplingImageProcessor(size: targetSize)
        let options: KingfisherOptionsInfo = [
            .scaleFactor(UIScreen.main.scale),
            .processor(processor),
            .cacheOriginalImage,
            .transition(.fade(0.3)),
            .requestModifier(RequestModifier.modifer)
        ]

        let resource = KF.ImageResource(downloadURL: url, cacheKey: urlString)
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options)
    }

    func setKFImage(urlString: String, completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?){
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }

        let targetSize = bounds.size == .zero ? frame.size : bounds.size
        let processor = DownsamplingImageProcessor(size: targetSize)
        let options: KingfisherOptionsInfo = [
            .scaleFactor(UIScreen.main.scale),
            .processor(processor),
            .cacheOriginalImage,
            .transition(.fade(0.3)),
            .requestModifier(RequestModifier.modifer)
        ]

        let resource = KF.ImageResource(downloadURL: url, cacheKey: urlString)
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options) { result in
            completion?(result)
        }
    }
}
