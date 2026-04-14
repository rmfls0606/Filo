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
    private func inferredAspectRatio() -> CGFloat? {
        for constraint in constraints {
            if constraint.firstItem as? UIView === self,
               constraint.secondItem as? UIView === self {
                if constraint.firstAttribute == .width && constraint.secondAttribute == .height && constraint.multiplier != 0 {
                    return constraint.multiplier
                }
                if constraint.firstAttribute == .height && constraint.secondAttribute == .width && constraint.multiplier != 0 {
                    return 1 / constraint.multiplier
                }
            }
        }
        return nil
    }

    private func resolvedTargetSize(_ targetSize: CGSize) -> CGSize {
        if targetSize != .zero {
            return targetSize
        }

        superview?.layoutIfNeeded()
        layoutIfNeeded()

        let fallback = bounds.size == .zero ? frame.size : bounds.size
        if fallback != .zero {
            return fallback
        }

        let screenWidth = UIScreen.main.bounds.width
        if let aspectRatio = inferredAspectRatio(), aspectRatio > 0 {
            return CGSize(width: screenWidth, height: screenWidth / aspectRatio)
        }

        return CGSize(width: screenWidth, height: screenWidth)
    }

    private func cacheKey(_ key: String, targetSize: CGSize) -> String {
        let normalized = resolvedTargetSize(targetSize)
        let scale = UIScreen.main.scale
        let width = Int((normalized.width * scale).rounded())
        let height = Int((normalized.height * scale).rounded())
        return "\(key)|\(width)x\(height)"
    }

    private func kfOptions(targetSize: CGSize, withFade: Bool) -> KingfisherOptionsInfo {
        let processor = DownsamplingImageProcessor(size: resolvedTargetSize(targetSize))
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

    func setKFImage(urlString: String, targetSize: CGSize){
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }
        let options = kfOptions(targetSize: targetSize, withFade: true)

        let resource = KF.ImageResource(downloadURL: url, cacheKey: cacheKey(urlString, targetSize: targetSize))
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options)
    }

    func setKFImage(urlString: String, targetSize: CGSize, completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?){
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }
        let options = kfOptions(targetSize: targetSize, withFade: true)

        let resource = KF.ImageResource(downloadURL: url, cacheKey: cacheKey(urlString, targetSize: targetSize))
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options) { result in
            completion?(result)
        }
    }
    
    func setKFImageNoFade(urlString: String, targetSize: CGSize) {
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }
        let options = kfOptions(targetSize: targetSize, withFade: false)

        let resource = KF.ImageResource(downloadURL: url, cacheKey: cacheKey(urlString, targetSize: targetSize))
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options)
    }
    
    func setKFImageNoFade(urlString: String, targetSize: CGSize, completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) {
        guard let url = URL(string: NetworkConfig.baseURL + "/" + urlString) else { return }
        let options = kfOptions(targetSize: targetSize, withFade: false)

        let resource = KF.ImageResource(downloadURL: url, cacheKey: cacheKey(urlString, targetSize: targetSize))
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options) { result in
            completion?(result)
        }
    }

    func setKFAbsoluteImage(url: URL, targetSize: CGSize, fade: Bool = true, completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        let options = kfOptions(targetSize: targetSize, withFade: fade)
        let resource = KF.ImageResource(downloadURL: url, cacheKey: cacheKey(url.absoluteString, targetSize: targetSize))
        kf.cancelDownloadTask()
        kf.indicatorType = .activity
        kf.setImage(with: resource, options: options) { result in
            completion?(result)
        }
    }
}
