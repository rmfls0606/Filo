//
//  ThumbnailCache.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation
import UIKit
import PDFKit
import CryptoKit

final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let ioQueue = DispatchQueue(label: "com.filo.thumbnail.cache.io", qos: .utility)
    private let workQueue = DispatchQueue(label: "com.filo.thumbnail.cache.work", qos: .userInitiated)
    private let inFlightQueue = DispatchQueue(label: "com.filo.thumbnail.cache.inflight")
    private var inFlightDataRequests: [String: [(Data?) -> Void]] = [:]
    private let fileManager = FileManager.default
    private let diskRootURL: URL

    private init() {
        memoryCache.totalCostLimit = 120 * 1024 * 1024
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            diskRootURL = cachesURL.appendingPathComponent("thumbnail-cache", isDirectory: true)
        } else {
            diskRootURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("thumbnail-cache", isDirectory: true)
        }
        try? fileManager.createDirectory(at: diskRootURL, withIntermediateDirectories: true)
    }

    func loadPDFThumbnail(url: URL, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let key = "pdf-thumb-\(url.absoluteString)-\(sizeKey(size))"
        if let cached = imageFromMemory(forKey: key) {
            completion(cached)
            return
        }
        loadImageFromDisk(forKey: key) { [weak self] image in
            guard let self else { return }
            if let image {
                self.storeInMemory(image, forKey: key)
                completion(image)
                return
            }
            self.fetchPDFData(url: url) { data in
                guard let data else {
                    completion(nil)
                    return
                }
                self.workQueue.async {
                    let image = Self.makePDFThumbnail(from: data, size: size)
                    if let image {
                        self.storeImage(image, forKey: key)
                    }
                    DispatchQueue.main.async {
                        completion(image)
                    }
                }
            }
        }
    }

    func loadPDFThumbnail(data: Data, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let key = "pdf-data-thumb-\(hash(data))-\(sizeKey(size))"
        if let cached = imageFromMemory(forKey: key) {
            completion(cached)
            return
        }
        loadImageFromDisk(forKey: key) { [weak self] image in
            guard let self else { return }
            if let image {
                self.storeInMemory(image, forKey: key)
                completion(image)
                return
            }
            self.workQueue.async {
                let image = Self.makePDFThumbnail(from: data, size: size)
                if let image {
                    self.storeImage(image, forKey: key)
                }
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }

    private func fetchPDFData(url: URL, completion: @escaping (Data?) -> Void) {
        let key = "pdf-data-\(url.absoluteString)"
        loadDataFromDisk(forKey: key) { [weak self] cachedData in
            guard let self else { return }
            if let cachedData {
                completion(cachedData)
                return
            }

            self.inFlightQueue.async {
                if self.inFlightDataRequests[key] != nil {
                    self.inFlightDataRequests[key]?.append(completion)
                    return
                }
                self.inFlightDataRequests[key] = [completion]
                var request = URLRequest(url: url)
                request.setValue(NetworkConfig.apiKey, forHTTPHeaderField: "SeSACKey")
                request.setValue(NetworkConfig.authorization, forHTTPHeaderField: "Authorization")
                let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
                    guard let self else { return }
                    if let data {
                        self.storeDataToDisk(data, forKey: key)
                    }
                    self.inFlightQueue.async {
                        let completions = self.inFlightDataRequests[key] ?? []
                        self.inFlightDataRequests[key] = nil
                        DispatchQueue.main.async {
                            completions.forEach { $0(data) }
                        }
                    }
                }
                task.resume()
            }
        }
    }

    private func imageFromMemory(forKey key: String) -> UIImage? {
        memoryCache.object(forKey: key as NSString)
    }

    private func storeInMemory(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }

    private func storeImage(_ image: UIImage, forKey key: String) {
        storeInMemory(image, forKey: key)
        ioQueue.async { [weak self] in
            guard let self else { return }
            let url = self.diskURL(forKey: key)
            let data = image.pngData() ?? image.jpegData(compressionQuality: 0.85)
            try? data?.write(to: url, options: .atomic)
        }
    }

    private func loadImageFromDisk(forKey key: String, completion: @escaping (UIImage?) -> Void) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let url = self.diskURL(forKey: key)
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(image) }
        }
    }

    private func storeDataToDisk(_ data: Data, forKey key: String) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let url = self.diskURL(forKey: key)
            try? data.write(to: url, options: .atomic)
        }
    }

    private func loadDataFromDisk(forKey key: String, completion: @escaping (Data?) -> Void) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let url = self.diskURL(forKey: key)
            let data = try? Data(contentsOf: url)
            DispatchQueue.main.async { completion(data) }
        }
    }

    private func diskURL(forKey key: String) -> URL {
        let filename = hashedFilename(key)
        return diskRootURL.appendingPathComponent(filename)
    }

    private func hashedFilename(_ key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func sizeKey(_ size: CGSize) -> String {
        let width = Int(ceil(size.width))
        let height = Int(ceil(size.height))
        let scale = Int(UIScreen.main.scale)
        return "\(max(width, 1))x\(max(height, 1))@\(scale)x"
    }

    private func hash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func makePDFThumbnail(from data: Data, size: CGSize) -> UIImage? {
        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else { return nil }
        let target = size == .zero ? CGSize(width: 72, height: 72) : size
        return page.thumbnail(of: target, for: .cropBox)
    }
}
