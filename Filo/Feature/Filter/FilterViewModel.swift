//
//  FilterViewModel.swift
//  Filo
//
//  Created by 이상민 on 12/18/25.
//

import Foundation
import RxSwift
import RxCocoa
import ImageIO
import Photos
import CoreLocation

final class FilterViewModel: ViewModelType{
    private let disposeBag = DisposeBag()
    
    struct Input{
        let categorySelected: Observable<FilterCategoryType>
        let imageSelected: Observable<Data>
        let editResult: Observable<(Data, FilterImagePropsEntity)>
        let assetIdentifier: Observable<String?>
        let priceInputText: ControlProperty<String>
    }
    
    struct Output{
        let categories: Driver<[FilterCategoryEntity]>
        let currentImageData: Driver<Data?>
        let currentFilterProps: Driver<FilterImagePropsEntity?>
        let originalImageData: Driver<Data?>
        let editEnabled: Driver<Bool>
        let metadata: Driver<FilterImageMetadata?>
        let priceNumberText: Driver<String>
    }
    
    private let metadataQueue = DispatchQueue(label: "com.filo.filter.metadata", qos: .userInitiated)
    private let metadataRelay = BehaviorRelay<FilterImageMetadata?>(value: nil)
    private let geocoder = CLGeocoder()
    private var lastGeocodedCoordinate: CLLocationCoordinate2D?
    private var latestOriginalData: Data?
    private var lastAssetIdentifier: String?
    
    func transform(input: Input) -> Output {
        let categoriesRelay = BehaviorRelay<[FilterCategoryEntity]>(
            value: FilterCategoryType.allCases.map{
                FilterCategoryEntity(type: $0)
            }
        )
        let imageDataRelay = BehaviorRelay<Data?>(value: nil)
        let originalImageDataRelay = BehaviorRelay<Data?>(value: nil)
        let filterPropsRelay = BehaviorRelay<FilterImagePropsEntity?>(value: nil)
        let priceNumberText = PublishRelay<String>()
        
        input.categorySelected
            .withLatestFrom(categoriesRelay){ selected, items in
                items.map{
                    var newItems = $0
                    newItems.isSelected = ($0.type == selected)
                    return newItems
                }
            }
            .bind(to: categoriesRelay)
            .disposed(by: disposeBag)
        
        input.imageSelected
            .subscribe(onNext: {data in
                self.latestOriginalData = data
                originalImageDataRelay.accept(data)
                imageDataRelay.accept(data)
                filterPropsRelay.accept(nil)
            })
            .disposed(by: disposeBag)
        
        input.editResult
            .subscribe(onNext: {data, props in
                imageDataRelay.accept(data)
                filterPropsRelay.accept(props)
            })
            .disposed(by: disposeBag)
        
        input.assetIdentifier
            .subscribe(onNext: { [weak self] identifier in
                guard let self else { return }
                self.lastAssetIdentifier = identifier
                self.metadataRelay.accept(nil)
                guard let identifier else {
                    self.updateMetadataFromData(self.latestOriginalData)
                    return
                }
                self.updateMetadataFromAsset(identifier: identifier, fallbackData: self.latestOriginalData)
            })
            .disposed(by: disposeBag)
        
        originalImageDataRelay
            .subscribe(onNext: { [weak self] data in
                guard let self else { return }
                if self.lastAssetIdentifier == nil {
                    self.updateMetadataFromData(data)
                }
            })
            .disposed(by: disposeBag)
        
        input.priceInputText
            .map { $0.formattedDecimal() }
            .distinctUntilChanged()
            .bind(to: priceNumberText)
            .disposed(by: disposeBag)
        
        return Output(
            categories: categoriesRelay.asDriver(),
            currentImageData: imageDataRelay.asDriver(),
            currentFilterProps: filterPropsRelay.asDriver(),
            originalImageData: originalImageDataRelay.asDriver(),
            editEnabled: imageDataRelay
                .map { $0 != nil }
                .asDriver(onErrorJustReturn: false),
            metadata: metadataRelay.asDriver(),
            priceNumberText: priceNumberText.asDriver(onErrorJustReturn: "")
        )
    }
    
    //data 기반 메타데이터 추출
    private func updateMetadataFromData(_ data: Data?) {
        guard let data else {
            metadataRelay.accept(nil)
            return
        }
        metadataQueue.async { [weak self] in
            guard let self else { return }
            let metadata = self.extractMetadata(from: data)
            DispatchQueue.main.async { [weak self] in
                self?.publishMetadata(metadata)
            }
        }
    }
    
    //identifier 기반 메타데이터 추출 실패 시 data기반으로 적용
    private func updateMetadataFromAsset(identifier: String, fallbackData: Data?) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else {
            updateMetadataFromData(fallbackData)
            return
        }
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        asset.requestContentEditingInput(with: options) { [weak self] input, _ in
            guard let self else { return }
            guard let url = input?.fullSizeImageURL else {
                self.updateMetadataFromData(fallbackData)
                return
            }
            self.metadataQueue.async { [weak self] in
                guard let self else { return }
                let metadata = self.extractMetadata(from: url)
                DispatchQueue.main.async { [weak self] in
                    self?.publishMetadata(metadata)
                }
            }
        }
    }
    
    private func extractMetadata(from data: Data) -> FilterImageMetadata? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }
        let fileSizeText = fileSizeString(from: data.count)
        return extractMetadata(from: properties, fileSizeMB: fileSizeText)
    }
    
    private func extractMetadata(from url: URL) -> FilterImageMetadata? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }
        
        let fileSizeText = fileSizeString(from: url)
        return extractMetadata(from: properties, fileSizeMB: fileSizeText)
    }
    
    //메타데이터 정보 추출
    private func extractMetadata(from properties: [CFString: Any], fileSizeMB: String?) -> FilterImageMetadata {
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]
        
        let make = (tiff?[kCGImagePropertyTIFFMake] as? String)
        let model = (tiff?[kCGImagePropertyTIFFModel] as? String)
        
        let lensModel = (exif?[kCGImagePropertyExifLensModel] as? String)
        let focalLength35mm = exif?[kCGImagePropertyExifFocalLenIn35mmFilm] as? Double
        let digitalZoomRatio = exif?[kCGImagePropertyExifDigitalZoomRatio] as? Double
        
        var focalLength = 0.0
        if let focalLength35mm,
           let digitalZoomRatio{
            focalLength = focalLength35mm / digitalZoomRatio
        }else if let exifFocalLength = exif?[kCGImagePropertyExifFocalLength] as? Double{
            focalLength = exifFocalLength
        }
        
        let fNumber = exif?[kCGImagePropertyExifFNumber] as? Double
        let isoValues = exif?[kCGImagePropertyExifISOSpeedRatings] as? [NSNumber]
        let iso = isoValues?.first?.intValue
        
        let width = properties[kCGImagePropertyPixelWidth] as? Int
        let height = properties[kCGImagePropertyPixelHeight] as? Int

        var latitude = gps?[kCGImagePropertyGPSLatitude] as? Double
        let latitudeRef = gps?[kCGImagePropertyGPSLatitudeRef] as? String
        if latitudeRef == "S", let value = latitude {
            latitude = -value
        }

        var longitude = gps?[kCGImagePropertyGPSLongitude] as? Double
        let longitudeRef = gps?[kCGImagePropertyGPSLongitudeRef] as? String
        if longitudeRef == "W", let value = longitude {
            longitude = -value
        }
        
        let megaPixel: Double?
        if let width, let height {
            megaPixel = (Double(width) * Double(height)) / 1_000_000.0
        } else {
            megaPixel = nil
        }
        
        return FilterImageMetadata(
            make: make,
            model: model,
            lensModel: lensModel,
            focalLength: focalLength,
            fNumber: fNumber,
            iso: iso,
            megaPixel: megaPixel,
            width: width,
            height: height,
            fileSizeMB: fileSizeMB,
            latitude: latitude,
            longitude: longitude,
            address: nil
        )
    }
    
    private func fileSizeString(from url: URL) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? NSNumber else {
            return nil
        }
        return fileSizeString(from: fileSize.intValue)
    }
    
    private func fileSizeString(from byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }

    private func publishMetadata(_ metadata: FilterImageMetadata?) {
        metadataRelay.accept(metadata)
        updateAddress(for: metadata)
    }

    private func updateAddress(for metadata: FilterImageMetadata?) {
        guard let metadata,
              let latitude = metadata.latitude,
              let longitude = metadata.longitude else {
            return
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        //이미 있고, 오차 범위가 작다면 그대로 사용
        if let last = lastGeocodedCoordinate,
           abs(last.latitude - coordinate.latitude) < 0.0001,
           abs(last.longitude - coordinate.longitude) < 0.0001 {
            return
        }

        //아니라면 저장
        lastGeocodedCoordinate = coordinate
        geocoder.cancelGeocode()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        Task { [weak self] in
            guard let self else { return }
            let address = await reverseGeocodeAddress(for: location)

            let updated = FilterImageMetadata(
                make: metadata.make,
                model: metadata.model,
                lensModel: metadata.lensModel,
                focalLength: metadata.focalLength,
                fNumber: metadata.fNumber,
                iso: metadata.iso,
                megaPixel: metadata.megaPixel,
                width: metadata.width,
                height: metadata.height,
                fileSizeMB: metadata.fileSizeMB,
                latitude: metadata.latitude,
                longitude: metadata.longitude,
                address: address
            )

            await MainActor.run { [weak self] in
                self?.metadataRelay.accept(updated)
            }
        }
    }

    private func reverseGeocodeAddress(for location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let first = placemarks.first else { return nil }
            return formatAddress(from: first)
        } catch {
            return nil
        }
    }

    private func formatAddress(from placemark: CLPlacemark) -> String? {
        let road = [placemark.thoroughfare, placemark.subThoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")

        let adminArea = placemark.administrativeArea

        if !road.isEmpty {
            if let adminArea, !adminArea.isEmpty {
                return "\(road) (\(adminArea))"
            }
            return road
        }

        return adminArea?.isEmpty == false ? adminArea : nil
    }
}
