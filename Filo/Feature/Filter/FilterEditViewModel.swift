//
//  FilterEditViewModel.swift
//  Filo
//
//  Created by 이상민 on 12/20/25.
//

import Foundation
import CoreImage
import ImageIO
import RxSwift
import RxCocoa
import UniformTypeIdentifiers

final class FilterEditViewModel: ViewModelType {
    struct Input {
        let selectedProp: ControlEvent<FilterPropItem>
        let sliderValueChanged: ControlProperty<Float>
        let compareButtonTapped: ControlEvent<Void>
        let sliderEditingEnded: ControlEvent<Void> //사용자가 슬라이더를 움직인 후 터치를 그만 두었을 때
        let undoButtonTapped: ControlEvent<Void>
        let redoButtonTapped: ControlEvent<Void>
    }

    struct Output {
        let imageData: Driver<Data>
        let filterProps: Driver<[FilterPropItem]>
        let sliderValue: Driver<Float>
        let isComparing: Driver<Bool>
    }

    private let imageRelay: BehaviorRelay<Data>
    private let disposeBag = DisposeBag()
    private let processingQueue = DispatchQueue(label: "com.filo.filter.edit", qos: .userInitiated)
    private let ciContext = CIContext()
    private let originalImageData: Data
    
    private var filteredImageData: Data
    private var pendingWorkItem: DispatchWorkItem?
    
    private var compareWorkItem: DispatchWorkItem?
    private let comparingRelay = BehaviorRelay<Bool>(value: false)
    private var filterValues: [FilterProps: Float] = [:]
    private var history: [[FilterProps: Float]] = [] //필터 적용 순서 기록
    private var historyIndex: Int = 0 //필터 적용 순서 기록 찾기용 index

    var latestImageData: Data { filteredImageData }
    var latestProps: FilterImagePropsEntity {
        makeEntity(from: filterValues)
    }

    init(imageData: Data, initialProps: FilterImagePropsEntity? = nil) {
        self.originalImageData = imageData
        self.imageRelay = BehaviorRelay(value: imageData)
        self.filteredImageData = imageData
        self.filterValues = [:]
        self.filterValues = valuesDictionary(entity: initialProps)
        self.history = [filterValues]
        if !isAllNeutral(filterValues) {
            applyFilters(with: filterValues)
        }
    }

    func transform(input: Input) -> Output {
        let selectedPropRelay = BehaviorRelay<FilterProps>(value: .blackPoint)
        let filterValuesRelay = BehaviorRelay<[FilterProps: Float]>(value: filterValues)
        let sliderValueRelay = BehaviorRelay<Float>(
            value: uiValue(from: value(for: .blackPoint, in: filterValues), for: .blackPoint)
        )

        input.selectedProp
            .map { $0.prop }
            .bind(to: selectedPropRelay)
            .disposed(by: disposeBag)

        input.sliderValueChanged
            .asObservable()
            .skip(1)
            .distinctUntilChanged()
            .withLatestFrom(Observable.combineLatest(selectedPropRelay, filterValuesRelay)) { value, pair in
                (value, pair.0, pair.1)
            }
            .map { sliderValue, prop, values in
                var updated = values
                let clampedUiValue = self.clampedUiValue(sliderValue, for: prop)
                let actual = self.actualValue(from: clampedUiValue, for: prop)
                updated[prop] = actual
                return updated
            }
            .bind(to: filterValuesRelay)
            .disposed(by: disposeBag)

        Observable
            .combineLatest(selectedPropRelay, filterValuesRelay)
            .map { selected, values in
                let actual = self.value(for: selected, in: values)
                return self.isNeutral(actual, for: selected) ? 0.0 : self.uiValue(from: actual, for: selected)
            }
            .bind(to: sliderValueRelay)
            .disposed(by: disposeBag)

        let filterPropsRelay = BehaviorRelay<[FilterPropItem]>(value: [])
        selectedPropRelay
            .map { selected in
                FilterProps.allCases.map { prop in
                    FilterPropItem(prop: prop, isSelected: prop == selected)
                }
            }
            .bind(to: filterPropsRelay)
            .disposed(by: disposeBag)

        filterValuesRelay
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] values in
                self?.filterValues = values
                self?.applyFilters(with: values)
            })
            .disposed(by: disposeBag)

        input.sliderEditingEnded
            .withLatestFrom(filterValuesRelay)
            .subscribe(onNext: { [weak self] values in
                guard let self else { return }
                if self.history.isEmpty {
                    self.history = [values]
                    self.historyIndex = 0
                } else if values != self.history[self.historyIndex] {
                    self.history = Array(self.history.prefix(self.historyIndex + 1))
                    self.history.append(values)
                    self.historyIndex = self.history.count - 1
                }
            })
            .disposed(by: disposeBag)

        input.compareButtonTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                guard !self.isAllNeutral(self.filterValues) else { return }
                self.comparingRelay.accept(true)
                self.compareWorkItem?.cancel()
                self.imageRelay.accept(self.originalImageData)
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    self.comparingRelay.accept(false)
                    self.imageRelay.accept(self.filteredImageData)
                }
                self.compareWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
            })
            .disposed(by: disposeBag)

        input.undoButtonTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                guard self.historyIndex > 0 else { return }
                self.historyIndex -= 1
                filterValuesRelay.accept(self.history[self.historyIndex])
            })
            .disposed(by: disposeBag)

        input.redoButtonTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                guard self.historyIndex + 1 < self.history.count else { return }
                self.historyIndex += 1
                filterValuesRelay.accept(self.history[self.historyIndex])
            })
            .disposed(by: disposeBag)

        return Output(
            imageData: imageRelay.asDriver(),
            filterProps: filterPropsRelay.asDriver(),
            sliderValue: sliderValueRelay.asDriver(),
            isComparing: comparingRelay.asDriver()
        )
    }
    
    private func isNeutral(_ actual: Float, for prop: FilterProps) -> Bool {
        abs(uiValue(from: actual, for: prop)) < 0.001
    }

    private func isAllNeutral(_ values: [FilterProps: Float]) -> Bool {
        FilterProps.allCases.allSatisfy { prop in
            isNeutral(value(for: prop, in: values), for: prop)
        }
    }

    private func makeEntity(from values: [FilterProps: Float]) -> FilterImagePropsEntity {
        FilterImagePropsEntity(
            blackPoint: Double(value(for: .blackPoint, in: values)),
            blur: Double(value(for: .blur, in: values)),
            brightness: Double(value(for: .brightness, in: values)),
            contrast: Double(value(for: .contrast, in: values)),
            exposure: Double(value(for: .exposure, in: values)),
            highlights: Double(value(for: .highlights, in: values)),
            noise: Double(value(for: .noise, in: values)),
            saturation: Double(value(for: .saturation, in: values)),
            shadows: Double(value(for: .shadows, in: values)),
            sharpness: Double(value(for: .sharpness, in: values)),
            temperature: Double(value(for: .temperature, in: values)),
            vignette: Double(value(for: .vignette, in: values))
        )
    }
    
    private func valuesDictionary(entity: FilterImagePropsEntity?) -> [FilterProps: Float] {
        guard let entity else {
            return defaultValues()
        }
        return defaultValues(updating: entity)
    }

    private func defaultValues(updating entity: FilterImagePropsEntity? = nil) -> [FilterProps: Float] {
        let base = Dictionary(uniqueKeysWithValues: FilterProps.allCases.map { ($0, actualValue(from: 0.0, for: $0)) })
        guard let entity else { return base }
        var updated = base
        updated[.blackPoint] = Float(entity.blackPoint)
        updated[.blur] = Float(entity.blur)
        updated[.brightness] = Float(entity.brightness)
        updated[.contrast] = Float(entity.contrast)
        updated[.exposure] = Float(entity.exposure)
        updated[.highlights] = Float(entity.highlights)
        updated[.noise] = Float(entity.noise)
        updated[.saturation] = Float(entity.saturation)
        updated[.shadows] = Float(entity.shadows)
        updated[.sharpness] = Float(entity.sharpness)
        updated[.temperature] = Float(entity.temperature)
        updated[.vignette] = Float(entity.vignette)
        return updated
    }

    private func value(for prop: FilterProps, in values: [FilterProps: Float]) -> Float {
        values[prop] ?? actualValue(from: 0.0, for: prop)
    }

    private func actualValue(from uiValue: Float, for prop: FilterProps) -> Float {
        let photoValue = photoValue(from: uiValue)
        let shapedPhotoValue = shapedPhotoValue(photoValue, for: prop)
        let actual: Float
        switch prop {
        case .blackPoint:
            actual = shapedPhotoValue / 500.0
        case .blur:
            actual = shapedPhotoValue / 5.0
        case .brightness:
            actual = shapedPhotoValue / 100.0
        case .contrast:
            actual = 1.0 + (shapedPhotoValue / 200.0)
        case .exposure:
            actual = shapedPhotoValue / 50.0
        case .highlights:
            actual = shapedPhotoValue / 100.0
        case .noise:
            actual = shapedPhotoValue / 500.0
        case .saturation:
            actual = 1.0 + (shapedPhotoValue / 100.0)
        case .shadows:
            actual = shapedPhotoValue / 100.0
        case .sharpness:
            actual = shapedPhotoValue / 35.0
        case .temperature:
            actual = shapedPhotoValue / 5.0
        case .vignette:
            actual = shapedPhotoValue / 50.0
        }
        return prop.clampedActualValue(actual)
    }

    private func clampedUiValue(_ value: Float, for prop: FilterProps) -> Float {
        switch prop {
        case .sharpness, .noise:
            return max(0.0, value)
        default:
            return value
        }
    }

    private func photoValue(from uiValue: Float) -> Float {
        uiValue * 20.0
    }

    private func uiValue(from actual: Float, for prop: FilterProps) -> Float {
        let photoValue: Float
        switch prop {
        case .blackPoint:
            photoValue = actual * 500.0
        case .blur:
            photoValue = actual * 5.0
        case .brightness:
            photoValue = actual * 100.0
        case .contrast:
            photoValue = (actual - 1.0) * 200.0
        case .exposure:
            photoValue = actual * 50.0
        case .highlights:
            photoValue = actual * 100.0
        case .noise:
            photoValue = actual * 500.0
        case .saturation:
            photoValue = (actual - 1.0) * 100.0
        case .shadows:
            photoValue = actual * 100.0
        case .sharpness:
            photoValue = actual * 35.0
        case .temperature:
            photoValue = actual * 5.0
        case .vignette:
            photoValue = actual * 50.0
        }
        let uiPhotoValue = inverseShapedPhotoValue(photoValue, for: prop)
        return max(-5.0, min(5.0, uiValue(from: uiPhotoValue)))
    }

    private func shapedPhotoValue(_ value: Float, for prop: FilterProps) -> Float {
        let sign: Float = value >= 0 ? 1 : -1
        let absValue = abs(value)
        let exponent: Float = (prop == .sharpness || prop == .noise) ? 1.6 : 1.2
        let shaped = pow(absValue / 100.0, exponent) * 100.0
        return sign * shaped
    }

    private func inverseShapedPhotoValue(_ value: Float, for prop: FilterProps) -> Float {
        let sign: Float = value >= 0 ? 1 : -1
        let absValue = abs(value)
        let exponent: Float = (prop == .sharpness || prop == .noise) ? 1.6 : 1.2
        let shaped = pow(absValue / 100.0, 1.0 / exponent) * 100.0
        return sign * shaped
    }

    private func uiValue(from photoValue: Float) -> Float {
        photoValue / 20.0
    }

    private func applyFilters(with values: [FilterProps: Float]) {
        let baseData = originalImageData
        if isAllNeutral(values) {
            filteredImageData = baseData
            if !comparingRelay.value {
                imageRelay.accept(baseData)
            }
            return
        }
        let workItem = DispatchWorkItem { [weak self] in
            let options: [CIImageOption: Any] = [.applyOrientationProperty: true]
            guard let self = self,
                  let inputImage = CIImage(data: baseData, options: options) else { return }

            let extent = inputImage.extent
            var ciImage = inputImage

            // blackPoint: 음수는 리프트, 양수는 크러시
            let blackPointValue = value(for: .blackPoint, in: values)
            if !isNeutral(blackPointValue, for: .blackPoint), blackPointValue < 0,
               let clampFilter = CIFilter(name: "CIColorClamp") {
                let lift = abs(blackPointValue)
                let minVector = CIVector(x: CGFloat(lift), y: CGFloat(lift), z: CGFloat(lift), w: 0)
                let maxVector = CIVector(x: 1, y: 1, z: 1, w: 1)
                clampFilter.setValue(ciImage, forKey: kCIInputImageKey)
                clampFilter.setValue(minVector, forKey: "inputMinComponents")
                clampFilter.setValue(maxVector, forKey: "inputMaxComponents")
                ciImage = clampFilter.outputImage ?? ciImage
            } else if !isNeutral(blackPointValue, for: .blackPoint), blackPointValue > 0,
                      let matrixFilter = CIFilter(name: "CIColorMatrix") {
                let bias = CGFloat(-blackPointValue)
                matrixFilter.setValue(ciImage, forKey: kCIInputImageKey)
                matrixFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
                matrixFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
                matrixFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
                matrixFilter.setValue(CIVector(x: bias, y: bias, z: bias, w: 0), forKey: "inputBiasVector")
                ciImage = matrixFilter.outputImage ?? ciImage
            }

            // blur: 양수는 블러, 음수는 샤픈으로 전환
            let blurValue = value(for: .blur, in: values)
            if !isNeutral(blurValue, for: .blur), blurValue > 0,
               let blurFilter = CIFilter(name: "CIGaussianBlur") {
                blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
                blurFilter.setValue(blurValue, forKey: kCIInputRadiusKey)
                if let output = blurFilter.outputImage?.cropped(to: extent) {
                    ciImage = output
                }
            }

            // brightness/contrast/saturation 묶음 적용
            let brightnessValue = value(for: .brightness, in: values)
            let contrastValue = value(for: .contrast, in: values)
            let saturationValue = value(for: .saturation, in: values)
            if !isNeutral(brightnessValue, for: .brightness)
                || !isNeutral(contrastValue, for: .contrast)
                || !isNeutral(saturationValue, for: .saturation),
               let colorFilter = CIFilter(name: "CIColorControls") {
                colorFilter.setValue(ciImage, forKey: kCIInputImageKey)
                colorFilter.setValue(brightnessValue, forKey: kCIInputBrightnessKey)
                colorFilter.setValue(contrastValue, forKey: kCIInputContrastKey)
                colorFilter.setValue(saturationValue, forKey: kCIInputSaturationKey)
                ciImage = colorFilter.outputImage ?? ciImage
            }

            // exposure: EV 기반으로 전체 밝기 보정
            let exposureValue = value(for: .exposure, in: values)
            if !isNeutral(exposureValue, for: .exposure),
               let exposureFilter = CIFilter(name: "CIExposureAdjust") {
                exposureFilter.setValue(ciImage, forKey: kCIInputImageKey)
                exposureFilter.setValue(exposureValue, forKey: kCIInputEVKey)
                ciImage = exposureFilter.outputImage ?? ciImage
            }

            let shadowsValue = value(for: .shadows, in: values)
            let highlightsValue = value(for: .highlights, in: values)
            // shadows/highlights: 암부/명부 보정
            if !isNeutral(shadowsValue, for: .shadows)
                || !isNeutral(highlightsValue, for: .highlights),
               let highlightFilter = CIFilter(name: "CIHighlightShadowAdjust") {
                highlightFilter.setValue(ciImage, forKey: kCIInputImageKey)
                highlightFilter.setValue(shadowsValue, forKey: "inputShadowAmount")
                highlightFilter.setValue(highlightsValue, forKey: "inputHighlightAmount")
                ciImage = highlightFilter.outputImage ?? ciImage
            }

            // noise: 노이즈 감소
            let noiseValue = value(for: .noise, in: values)
            if !isNeutral(noiseValue, for: .noise),
               let noiseFilter = CIFilter(name: "CINoiseReduction") {
                noiseFilter.setValue(ciImage, forKey: kCIInputImageKey)
                noiseFilter.setValue(noiseValue, forKey: "inputNoiseLevel")
                noiseFilter.setValue(0.4, forKey: "inputSharpness")
                ciImage = noiseFilter.outputImage ?? ciImage
            }

            // sharpness: 선명도 + blur 음수분을 샤픈으로 흡수
            let sharpnessValue = value(for: .sharpness, in: values)
            let blurSharpenValue = blurValue < 0 ? min(2.0, abs(blurValue) / 10.0) : 0.0
            let combinedSharpness = min(2.0, sharpnessValue + blurSharpenValue)
            if combinedSharpness > 0,
               let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
                sharpenFilter.setValue(ciImage, forKey: kCIInputImageKey)
                sharpenFilter.setValue(combinedSharpness, forKey: kCIInputSharpnessKey)
                ciImage = sharpenFilter.outputImage ?? ciImage
            }

            // temperature: 색온도 보정
            let temperatureValue = value(for: .temperature, in: values)
            if !isNeutral(temperatureValue, for: .temperature),
               let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
                let neutral = CIVector(
                    x: 6500 + CGFloat((CGFloat(temperatureValue) * 150)),
                    y: 0
                )
                let target = CIVector(x: 6500, y: 0)
                temperatureFilter.setValue(ciImage, forKey: kCIInputImageKey)
                temperatureFilter.setValue(neutral, forKey: "inputNeutral")
                temperatureFilter.setValue(target, forKey: "inputTargetNeutral")
                ciImage = temperatureFilter.outputImage ?? ciImage
            }


            // vignette: 주변부 어둡게(비네팅)
            let vignetteValue = value(for: .vignette, in: values)
            if !isNeutral(vignetteValue, for: .vignette),
               let vignetteFilter = CIFilter(name: "CIVignette") {
                vignetteFilter.setValue(ciImage, forKey: kCIInputImageKey)
                vignetteFilter.setValue(vignetteValue, forKey: kCIInputIntensityKey)
                vignetteFilter.setValue(max(extent.width, extent.height) / 2, forKey: kCIInputRadiusKey)
                ciImage = vignetteFilter.outputImage ?? ciImage
            }

            // 블러 등으로 생긴 여백을 원본 영역으로 크롭
            let cropped = ciImage.cropped(to: extent)
            guard let cgImage = self.ciContext.createCGImage(cropped, from: extent) else { return }
            guard let outputData = jpegData(from: cgImage, compressionQuality: 0.9) else { return }

            DispatchQueue.main.async {
                self.filteredImageData = outputData
                if !self.comparingRelay.value {
                    self.imageRelay.accept(outputData)
                }
            }
        }
        // 이전 작업을 취소하고 최신 작업만 실행
        pendingWorkItem?.cancel()
        pendingWorkItem = workItem
        processingQueue.async(execute: workItem)
    }

    private func jpegData(from cgImage: CGImage, compressionQuality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
