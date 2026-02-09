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
import UIKit

final class FilterViewModel: ViewModelType{
    struct EditSeed {
        let filterId: String
        let category: String
        let title: String
        let description: String
        let price: Int
        let files: [String]
        let filterValues: FilterValuesDTO?
        let photoMetadata: PhotoMetadataDTO?
    }
    
    enum Mode {
        case create
        case edit(EditSeed)
    }
    
    private let disposeBag = DisposeBag()
    private let mode: Mode
    
    struct Input{
        let categorySelected: Observable<FilterCategoryType>
        let imageSelected: Observable<Data>
        let editResult: Observable<(Data, FilterImagePropsEntity)>
        let assetIdentifier: Observable<String?>
        let resetForm: Observable<Void>
        let filterNameText: ControlProperty<String>
        let filterIntroduceText: ControlProperty<String>
        let priceInputText: ControlProperty<String>
        let saveButtonTapped: ControlEvent<()>?
    }
    
    struct Output{
        let categories: Driver<[FilterCategoryEntity]>
        let currentImageData: Driver<Data?>
        let currentFilterProps: Driver<FilterImagePropsEntity?>
        let originalImageData: Driver<Data?>
        let editEnabled: Driver<Bool>
        let metadata: Driver<FilterImageMetadata?>
        let priceNumberText: Driver<String>
        let saveEnabled: Driver<Bool>
        let saveSuccess: Signal<Void>
        let networkError: Signal<NetworkError>
    }
    
    private let metadataQueue = DispatchQueue(label: "com.filo.filter.metadata", qos: .userInitiated)
    private let metadataRelay = BehaviorRelay<FilterImageMetadata?>(value: nil)
    private let geocoder = CLGeocoder()
    private var lastGeocodedCoordinate: CLLocationCoordinate2D?
    private var latestOriginalData: Data?
    private var lastAssetIdentifier: String?
    
    var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    var initialSeed: EditSeed? {
        if case .edit(let seed) = mode { return seed }
        return nil
    }
    
    init(mode: Mode = .create) {
        self.mode = mode
    }
    
    func transform(input: Input) -> Output {
        let initialCategory = initialSeed.flatMap { FilterCategoryType(rawValue: $0.category) }
        let initialPriceText = initialSeed.map { "\($0.price)".formattedDecimal() } ?? ""
        let initialPriceValue = initialSeed?.price ?? 0
        let initialProps = initialSeed.flatMap { makeInitialFilterProps(from: $0.filterValues) }
        let initialMetadata = initialSeed.flatMap { makeInitialMetadata(from: $0.photoMetadata) }
        
        let categoriesRelay = BehaviorRelay<[FilterCategoryEntity]>(
            value: FilterCategoryType.allCases.map{
                FilterCategoryEntity(type: $0, isSelected: $0 == initialCategory)
            }
        )
        let imageDataRelay = BehaviorRelay<Data?>(value: nil)
        let originalImageDataRelay = BehaviorRelay<Data?>(value: nil)
        let filterPropsRelay = BehaviorRelay<FilterImagePropsEntity?>(value: initialProps)
        let priceNumberText = BehaviorRelay<String>(value: initialPriceText)
        let priceValueRelay = BehaviorRelay<Int>(value: initialPriceValue)
        let filterNameRelay = BehaviorRelay<String>(value: initialSeed?.title ?? "")
        let selectedCategoryRelay = BehaviorRelay<FilterCategoryType?>(value: initialCategory)
        let filterIntroduceRelay = BehaviorRelay<String>(value: initialSeed?.description ?? "")
        let saveSuccessRelay = PublishRelay<Void>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        
        if let initialMetadata {
            publishMetadata(initialMetadata)
        }
        preloadEditImagesIfNeeded(imageDataRelay: imageDataRelay, originalImageDataRelay: originalImageDataRelay, networkErrorRelay: networkErrorRelay)
        
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

        input.categorySelected
            .bind(to: selectedCategoryRelay)
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

        priceNumberText
            .map { [weak self] in self?.parsePrice($0) ?? 0 }
            .distinctUntilChanged()
            .bind(to: priceValueRelay)
            .disposed(by: disposeBag)

        input.filterNameText
            .bind(to: filterNameRelay)
            .disposed(by: disposeBag)

        input.filterIntroduceText
            .bind(to: filterIntroduceRelay)
            .disposed(by: disposeBag)
        
        input.resetForm
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                guard case .create = self.mode else { return }
                
                categoriesRelay.accept(
                    FilterCategoryType.allCases.map {
                        FilterCategoryEntity(type: $0, isSelected: false)
                    }
                )
                selectedCategoryRelay.accept(nil)
                filterNameRelay.accept("")
                filterIntroduceRelay.accept("")
                priceNumberText.accept("")
                priceValueRelay.accept(0)
                imageDataRelay.accept(nil)
                originalImageDataRelay.accept(nil)
                filterPropsRelay.accept(nil)
                self.latestOriginalData = nil
                self.lastAssetIdentifier = nil
                self.metadataRelay.accept(nil)
            })
            .disposed(by: disposeBag)

        input.saveButtonTapped?
            .withLatestFrom(Observable.combineLatest(
                selectedCategoryRelay,
                filterNameRelay,
                filterIntroduceRelay,
                priceNumberText,
                imageDataRelay,
                originalImageDataRelay,
                filterPropsRelay,
                metadataRelay
            ))
            .subscribe(onNext: { [weak self] category, title, description, priceText, imageData, originalData, props, metadata in
                guard let self else { return }
                guard let category,
                      let imageData else { return }

                Task {
                    do {
                        let filesPayloads = self.makeMultipartFiles(original: originalData, filtered: imageData)
                        
                        let filesDTO: FilterFilesResponseDTO = try await NetworkManager.shared.upload(
                            FilterRouter.files,
                            files: filesPayloads
                        )

                        let requestBody = self.makeCreateFilterRequestBody(
                            category: category,
                            title: title,
                            description: description,
                            priceText: priceText,
                            fileURLs: filesDTO.files,
                            props: props,
                            metadata: metadata
                        )
                        
                        switch self.mode {
                        case .create:
                            let _: FilterResponseDTO = try await NetworkManager.shared.request(
                                FilterRouter.createFilter(requestBody: requestBody)
                            )
                        case .edit(let seed):
                            let _: FilterResponseDTO = try await NetworkManager.shared.request(
                                FilterRouter.updateFilter(filterId: seed.filterId, requestBody: requestBody)
                            )
                        }
                        saveSuccessRelay.accept(())
                    } catch(let error as NetworkError) {
                        networkErrorRelay.accept(error)
                    }catch(let error){
                        networkErrorRelay.accept(NetworkError.unknown(error))
                    }
                }
            })
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
            priceNumberText: priceNumberText.asDriver(onErrorJustReturn: ""),
            saveEnabled: Observable.combineLatest(
                selectedCategoryRelay,
                filterNameRelay,
                filterIntroduceRelay,
                priceValueRelay,
                imageDataRelay,
                originalImageDataRelay
            )
            .map { category, title, description, price, imageData, originalData in
                guard category != nil else { return false }
                guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
                guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
                guard price >= 0 else { return false }
                return imageData != nil && originalData != nil
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false),
            saveSuccess: saveSuccessRelay.asSignal(),
            networkError: networkErrorRelay.asSignal()
        )
    }

    private func makeMultipartFiles(original: Data?, filtered: Data) -> [MultipartFile] {
        var files: [MultipartFile] = []

        if let original {
            let mime = detectMimeType(original)
            let ext = fileExtension(for: mime)
            if mime == "image/png", let image = UIImage(data: original), let jpg = image.jpegData(compressionQuality: 0.9) {
                files.append(MultipartFile(
                    data: jpg,
                    name: "files",
                    fileName: "previews_original.jpg",
                    mimeType: "image/jpeg"
                ))
            } else {
                files.append(MultipartFile(
                    data: original,
                    name: "files",
                    fileName: "previews_original.\(ext)",
                    mimeType: mime
                ))
            }
        }

        let filteredMime = detectMimeType(filtered)
        let filteredExt = fileExtension(for: filteredMime)
        files.append(MultipartFile(
            data: filtered,
            name: "files",
            fileName: "previews_filtered.\(filteredExt)",
            mimeType: filteredMime
        ))

        return files
    }

    private func detectMimeType(_ data: Data) -> String {
        if data.count >= 4 {
            let signature = [UInt8](data.prefix(4))
            if signature == [0x89, 0x50, 0x4E, 0x47] {
                return "image/png"
            }
            if signature[0] == 0xFF && signature[1] == 0xD8 {
                return "image/jpeg"
            }
        }
        return "image/jpeg"
    }

    private func fileExtension(for mimeType: String) -> String {
        switch mimeType {
        case "image/png":
            return "png"
        case "image/jpeg":
            return "jpg"
        default:
            return "jpg"
        }
    }

    private func makeCreateFilterRequestBody(
        category: FilterCategoryType,
        title: String,
        description: String,
        priceText: String,
        fileURLs: [String],
        props: FilterImagePropsEntity?,
        metadata: FilterImageMetadata?
    ) -> CreateFilterRequestBody {
        let price = parsePrice(priceText)
        let values = props ?? FilterImagePropsEntity(
            blackPoint: 0,
            blur: 0,
            brightness: 0,
            contrast: 1,
            exposure: 0,
            highlights: 1,
            noise: 0,
            saturation: 1,
            shadows: 0,
            sharpness: 0,
            temperature: 0,
            vignette: 0
        )

        let dateText = metadata?.dateTimeOriginal

        let cameraText = [metadata?.make, metadata?.model]
            .compactMap { $0 }
            .joined(separator: " ")
        let cameraValue = cameraText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : cameraText

        let metadataBody = CreateFilterMetadata(
            camera: cameraValue,
            lensInfo: metadata?.lensModel,
            focalLength: sanitize(metadata?.focalLength),
            aperture: sanitize(metadata?.fNumber),
            iso: metadata?.iso,
            shutterSpeed: metadata?.shutterSpeed,
            pixelWidth: metadata?.width,
            pixelHeight: metadata?.height,
            fileSize: sanitize(metadata?.fileSizeBytes),
            format: metadata?.format,
            dateTimeOriginal: dateText,
            latitude: sanitize(metadata?.latitude),
            longitude: sanitize(metadata?.longitude)
        )

        let valuesBody = CreateFilterValues(
            brightness: sanitize(values.brightness),
            exposure: sanitize(values.exposure),
            contrast: sanitize(values.contrast),
            saturation: sanitize(values.saturation),
            sharpness: sanitize(values.sharpness),
            blur: sanitize(values.blur),
            vignette: sanitize(values.vignette),
            noise_reduction: sanitize(values.noise),
            highlights: sanitize(values.highlights),
            shadows: sanitize(values.shadows) ?? 0,
            temperature: sanitize(uiTemperatureToKelvin(values.temperature)),
            black_point: sanitize(values.blackPoint)
        )

        return CreateFilterRequestBody(
            category: category.rawValue,
            title: title,
            price: price,
            description: description,
            files: fileURLs,
            photo_metadata: metadataBody,
            filter_values: valuesBody
        )
    }

    private func parsePrice(_ text: String) -> Int {
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 0
    }

    private func sanitize(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return value
    }
    
    private func makeInitialFilterProps(from dto: FilterValuesDTO?) -> FilterImagePropsEntity? {
        guard let dto else { return nil }
        return FilterImagePropsEntity(
            blackPoint: dto.blackPoint ?? 0,
            blur: dto.blur ?? 0,
            brightness: dto.brightness ?? 0,
            contrast: dto.contrast ?? 1,
            exposure: dto.exposure ?? 0,
            highlights: dto.highlights ?? 1,
            noise: dto.noiseReduction ?? 0,
            saturation: dto.saturation ?? 1,
            shadows: dto.shadows ?? 0,
            sharpness: dto.sharpness ?? 0,
            temperature: incomingTemperatureToUI(dto.temperature),
            vignette: dto.vignette ?? 0
        )
    }

    private func uiTemperatureToKelvin(_ uiValue: Double) -> Double {
        let clamped = min(max(uiValue, -100.0), 100.0)
        return 6500.0 + (clamped * 25.0)
    }

    private func incomingTemperatureToUI(_ value: Double?) -> Double {
        guard let value else { return 0.0 }
        // Kelvin absolute value (legacy/서버 기준): 1000K 이상으로 판단
        if value >= 1000.0 {
            let ui = (value - 6500.0) / 25.0
            return min(max(ui, -100.0), 100.0)
        }
        // 이미 보정값으로 저장된 데이터(레거시 클라이언트 포함)
        return min(max(value, -100.0), 100.0)
    }
    
    private func makeInitialMetadata(from dto: PhotoMetadataDTO?) -> FilterImageMetadata? {
        guard let dto else { return nil }
        let (make, model) = splitCamera(dto.camera)
        let megaPixel: Double?
        if let width = dto.pixelWidth, let height = dto.pixelHeight {
            megaPixel = (Double(width) * Double(height)) / 1_000_000.0
        } else {
            megaPixel = nil
        }
        let fileSizeMB = dto.fileSize.map { fileSizeString(from: Int($0)) }
        return FilterImageMetadata(
            make: make,
            model: model,
            lensModel: dto.lensInfo,
            focalLength: dto.focalLength,
            fNumber: dto.aperture,
            iso: dto.iso,
            megaPixel: megaPixel,
            width: dto.pixelWidth,
            height: dto.pixelHeight,
            fileSizeMB: fileSizeMB,
            fileSizeBytes: dto.fileSize,
            format: dto.format,
            dateTimeOriginal: dto.dateTimeOriginal,
            shutterSpeed: dto.shutterSpeed,
            latitude: dto.latitude,
            longitude: dto.longitude,
            address: nil
        )
    }
    
    private func splitCamera(_ camera: String?) -> (String?, String?) {
        guard let camera else { return (nil, nil) }
        let normalized = camera.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return (nil, nil) }
        let parts = normalized.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if parts.count <= 1 {
            return (nil, parts.first)
        }
        return (parts.first, parts.dropFirst().joined(separator: " "))
    }
    
    private func preloadEditImagesIfNeeded(
        imageDataRelay: BehaviorRelay<Data?>,
        originalImageDataRelay: BehaviorRelay<Data?>,
        networkErrorRelay: PublishRelay<NetworkError>
    ) {
        guard case .edit(let seed) = mode else { return }
        guard !seed.files.isEmpty else { return }
        
        Task { [weak self] in
            guard let self else { return }
            let originalPath = seed.files.first
            let filteredPath = seed.files.count > 1 ? seed.files[1] : seed.files.first
            
            async let originalData = self.fetchImageData(relativePath: originalPath)
            async let filteredData = self.fetchImageData(relativePath: filteredPath)
            
            do {
                let original = try await originalData
                let filtered = try await filteredData
                await MainActor.run {
                    if let original {
                        self.latestOriginalData = original
                        originalImageDataRelay.accept(original)
                    }
                    if let filtered {
                        imageDataRelay.accept(filtered)
                    } else if let original {
                        imageDataRelay.accept(original)
                    }
                }
            } catch let error as NetworkError {
                networkErrorRelay.accept(error)
            } catch {
                networkErrorRelay.accept(.unknown(error))
            }
        }
    }
    
    private func fetchImageData(relativePath: String?) async throws -> Data? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        guard let url = URL(string: NetworkConfig.baseURL + "/" + relativePath) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue(NetworkConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        request.setValue(NetworkConfig.authorization, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            return nil
        }
        return data
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
        let imageType = CGImageSourceGetType(source) as String?
        let fileSizeText = fileSizeString(from: data.count)
        return extractMetadata(from: properties, fileSizeMB: fileSizeText, fileSizeBytes: Double(data.count), imageType: imageType)
    }
    
    private func extractMetadata(from url: URL) -> FilterImageMetadata? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }
        let imageType = CGImageSourceGetType(source) as String?
        let fileSizeText = fileSizeString(from: url)
        let fileSizeBytes = fileSizeBytes(from: url)
        return extractMetadata(from: properties, fileSizeMB: fileSizeText, fileSizeBytes: fileSizeBytes, imageType: imageType)
    }
    
    //메타데이터 정보 추출
    private func extractMetadata(from properties: [CFString: Any], fileSizeMB: String?, fileSizeBytes: Double?, imageType: String?) -> FilterImageMetadata {
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
        let exposureTime = exif?[kCGImagePropertyExifExposureTime] as? Double
        let shutterSpeed = formatShutterSpeed(exposureTime)
        
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

        let format = imageType.map { normalizeFormat($0) }
        let dateTimeOriginal = exif?[kCGImagePropertyExifDateTimeOriginal] as? String
        
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
            fileSizeBytes: fileSizeBytes,
            format: format,
            dateTimeOriginal: dateTimeOriginal,
            shutterSpeed: shutterSpeed,
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

    private func fileSizeBytes(from url: URL) -> Double? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? NSNumber else {
            return nil
        }
        return fileSize.doubleValue
    }
    
    private func fileSizeString(from byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }

    private func normalizeFormat(_ value: String) -> String {
        let lower = value.lowercased()
        if lower.contains("jpeg") || lower.contains("jpg") {
            return "jpeg"
        }
        if lower.contains("png") {
            return "png"
        }
        return lower
    }

    private func formatShutterSpeed(_ exposureTime: Double?) -> String? {
        guard let exposureTime, exposureTime > 0 else { return nil }
        if exposureTime >= 1.0 {
            let rounded = String(format: "%.1f", exposureTime).trimmingCharacters(in: CharacterSet(charactersIn: "0").union(.punctuationCharacters))
            return "\(rounded) sec"
        } else {
            let denominator = Int(round(1.0 / exposureTime))
            return "1/\(max(1, denominator)) sec"
        }
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
                fileSizeBytes: metadata.fileSizeBytes,
                format: metadata.format,
                dateTimeOriginal: metadata.dateTimeOriginal,
                shutterSpeed: metadata.shutterSpeed,
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
