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
    private let signedSliderDisplayRange: ClosedRange<Float> = -100...100
    private let positiveSliderDisplayRange: ClosedRange<Float> = 0...100

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
        let sliderRange: Driver<ClosedRange<Float>>
        let sliderValue: Driver<Float>
        let isComparing: Driver<Bool>
        let canUndo: Driver<Bool>
        let canRedo: Driver<Bool>
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

    func previewImageData() -> Driver<Data> {
        imageRelay.asDriver()
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
            value: {
                let prop: FilterProps = .blackPoint
                let actual = prop.clampedActualValue(filterValues[prop] ?? prop.defaultValue)
                return self.toSliderValue(actual, for: prop)
            }()
        )
        let canUndoRelay = BehaviorRelay<Bool>(value: historyIndex > 0)
        let canRedoRelay = BehaviorRelay<Bool>(value: historyIndex + 1 < history.count)
        
        let updateHistoryState: () -> Void = { [weak self] in
            guard let self else { return }
            canUndoRelay.accept(self.historyIndex > 0)
            canRedoRelay.accept(self.historyIndex + 1 < self.history.count)
        }

        input.selectedProp
            .map { $0.prop }
            .bind(to: selectedPropRelay)
            .disposed(by: disposeBag)

        input.sliderValueChanged
            .asObservable()
            .distinctUntilChanged()
            .withLatestFrom(Observable.combineLatest(selectedPropRelay, filterValuesRelay)) { value, pair in
                (value, pair.0, pair.1)
            }
            .map { sliderValue, prop, values in
                var updated = values
                let rawActual = self.toActualValue(sliderValue, for: prop)
                let actual = prop.clampedActualValue(rawActual)
                updated[prop] = actual
                return updated
            }
            .bind(to: filterValuesRelay)
            .disposed(by: disposeBag)

        Observable
            .combineLatest(selectedPropRelay, filterValuesRelay)
            .map { selected, values in
                let actual = selected.clampedActualValue(values[selected] ?? selected.defaultValue)
                return self.toSliderValue(actual, for: selected)
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

        let sliderRangeRelay = BehaviorRelay<ClosedRange<Float>>(value: signedSliderDisplayRange)
        selectedPropRelay
            .map { self.sliderRange(for: $0) }
            .bind(to: sliderRangeRelay)
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
                updateHistoryState()
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
                updateHistoryState()
            })
            .disposed(by: disposeBag)

        input.redoButtonTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                guard self.historyIndex + 1 < self.history.count else { return }
                self.historyIndex += 1
                filterValuesRelay.accept(self.history[self.historyIndex])
                updateHistoryState()
            })
            .disposed(by: disposeBag)

        return Output(
            imageData: imageRelay.asDriver(),
            filterProps: filterPropsRelay.asDriver(),
            sliderRange: sliderRangeRelay.asDriver(),
            sliderValue: sliderValueRelay.asDriver(),
            isComparing: comparingRelay.asDriver(),
            canUndo: canUndoRelay.asDriver(),
            canRedo: canRedoRelay.asDriver()
        )
    }
    
    private func isNeutral(_ actual: Float, for prop: FilterProps) -> Bool {
        abs(actual - prop.defaultValue) < 0.0001
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
        let base = Dictionary(uniqueKeysWithValues: FilterProps.allCases.map { ($0, $0.defaultValue) })
        guard let entity else { return base }
        var updated = base
        updated[.blackPoint] = FilterProps.blackPoint.clampedActualValue(Float(entity.blackPoint))
        updated[.blur] = FilterProps.blur.clampedActualValue(Float(entity.blur))
        updated[.brightness] = FilterProps.brightness.clampedActualValue(Float(entity.brightness))
        updated[.contrast] = FilterProps.contrast.clampedActualValue(Float(entity.contrast))
        updated[.exposure] = FilterProps.exposure.clampedActualValue(Float(entity.exposure))
        updated[.highlights] = FilterProps.highlights.clampedActualValue(Float(entity.highlights))
        updated[.noise] = FilterProps.noise.clampedActualValue(Float(entity.noise))
        updated[.saturation] = FilterProps.saturation.clampedActualValue(Float(entity.saturation))
        updated[.shadows] = FilterProps.shadows.clampedActualValue(Float(entity.shadows))
        updated[.sharpness] = FilterProps.sharpness.clampedActualValue(Float(entity.sharpness))
        updated[.temperature] = FilterProps.temperature.clampedActualValue(Float(entity.temperature))
        updated[.vignette] = FilterProps.vignette.clampedActualValue(Float(entity.vignette))
        return updated
    }

    private func value(for prop: FilterProps, in values: [FilterProps: Float]) -> Float {
        prop.clampedActualValue(values[prop] ?? prop.defaultValue)
    }

    private func sliderRange(for prop: FilterProps) -> ClosedRange<Float> {
        switch prop {
        case .noise, .sharpness:
            return positiveSliderDisplayRange
        default:
            return signedSliderDisplayRange
        }
    }

    private func toActualValue(_ sliderValue: Float, for prop: FilterProps) -> Float {
        let range = sliderRange(for: prop)
        let sliderMin = range.lowerBound
        let sliderMax = range.upperBound
        let actualMin = prop.valueRange.lowerBound
        let actualMax = prop.valueRange.upperBound
        let normalized = (sliderValue - sliderMin) / max(0.0001, (sliderMax - sliderMin))
        let actual = actualMin + (normalized * (actualMax - actualMin))
        return prop.clampedActualValue(actual)
    }

    private func toSliderValue(_ actualValue: Float, for prop: FilterProps) -> Float {
        let range = sliderRange(for: prop)
        let sliderMin = range.lowerBound
        let sliderMax = range.upperBound
        let actualMin = prop.valueRange.lowerBound
        let actualMax = prop.valueRange.upperBound
        let normalized = (actualValue - actualMin) / max(0.0001, (actualMax - actualMin))
        let slider = sliderMin + (normalized * (sliderMax - sliderMin))
        return min(max(slider, sliderMin), sliderMax)
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

            // brightness: 양수는 EV, 음수는 ColorControls로 분기해 자연스러운 톤 유지
            let brightnessValue = value(for: .brightness, in: values)
            if !isNeutral(brightnessValue, for: .brightness) {
                if brightnessValue >= 0,
                   let brightnessFilter = CIFilter(name: "CIExposureAdjust") {
                    brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
                    brightnessFilter.setValue(brightnessValue * 0.7, forKey: kCIInputEVKey)
                    ciImage = brightnessFilter.outputImage ?? ciImage
                } else if let brightnessFilter = CIFilter(name: "CIColorControls") {
                    brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
                    brightnessFilter.setValue(brightnessValue * 0.2, forKey: kCIInputBrightnessKey)
                    ciImage = brightnessFilter.outputImage ?? ciImage
                }
            }

            // contrast: 대비
            let contrastValue = value(for: .contrast, in: values)
            if !isNeutral(contrastValue, for: .contrast),
               let contrastFilter = CIFilter(name: "CIColorControls") {
                contrastFilter.setValue(ciImage, forKey: kCIInputImageKey)
                contrastFilter.setValue(contrastValue, forKey: kCIInputContrastKey)
                ciImage = contrastFilter.outputImage ?? ciImage
            }

            // exposure: EV 기반으로 전체 밝기 보정
            let exposureValue = value(for: .exposure, in: values)
            if !isNeutral(exposureValue, for: .exposure),
               let exposureFilter = CIFilter(name: "CIExposureAdjust") {
                exposureFilter.setValue(ciImage, forKey: kCIInputImageKey)
                exposureFilter.setValue(exposureValue, forKey: kCIInputEVKey)
                ciImage = exposureFilter.outputImage ?? ciImage
            }
            
            // highlights: 명부 보정
            let highlightActual = value(for: .highlights, in: values)

            if !isNeutral(highlightActual, for: .highlights),
               let highlightFilter = CIFilter(name: "CIHighlightShadowAdjust") {
                // Photos 근사 1안: 단일 하이라이트 필터 + 완만한 곡선 매핑
                // 중립은 1.0, -방향은 0.0 쪽, +방향은 2.0 쪽으로 이동
                let delta = highlightActual - 1.0 // -1...1
                let mapped: Float
                if delta >= 0 {
                    // 1.0 초과 구간은 필터 체감이 약해 기본값 유지 후 추가 보정으로 처리
                    mapped = 1.0
                } else {
                    mapped = 1.0 - (pow(-delta, 0.9) * 0.55)
                }

                highlightFilter.setValue(ciImage, forKey: kCIInputImageKey)
                highlightFilter.setValue(min(2.0, max(0.0, mapped)), forKey: "inputHighlightAmount")
                ciImage = highlightFilter.outputImage ?? ciImage

                // +방향(1.0~2.0) 체감 보강: 피사체 중간톤은 살리고 상단 하이라이트만 롤오프
                if delta > 0 {
                    let t = pow(min(1.0, delta), 0.75)
                    if let toneCurve = CIFilter(name: "CIToneCurve") {
                        toneCurve.setValue(ciImage, forKey: kCIInputImageKey)
                        toneCurve.setValue(CIVector(x: 0.00, y: 0.00), forKey: "inputPoint0")
                        toneCurve.setValue(CIVector(x: 0.25, y: 0.25 + (0.01 * CGFloat(t))), forKey: "inputPoint1")
                        toneCurve.setValue(CIVector(x: 0.50, y: 0.50 + (0.01 * CGFloat(t))), forKey: "inputPoint2")
                        toneCurve.setValue(CIVector(x: 0.75, y: 0.75 - (0.14 * CGFloat(t))), forKey: "inputPoint3")
                        toneCurve.setValue(CIVector(x: 1.00, y: 1.00 - (0.30 * CGFloat(t))), forKey: "inputPoint4")
                        ciImage = toneCurve.outputImage ?? ciImage
                    }
                    if let exposure = CIFilter(name: "CIExposureAdjust") {
                        exposure.setValue(ciImage, forKey: kCIInputImageKey)
                        exposure.setValue(0.12 * t, forKey: kCIInputEVKey)
                        ciImage = exposure.outputImage ?? ciImage
                    }
                }
            }
            
            // noise: 노이즈 감소
            let noiseValue = value(for: .noise, in: values)
            if !isNeutral(noiseValue, for: .noise),
               let noiseFilter = CIFilter(name: "CINoiseReduction") {
                noiseFilter.setValue(ciImage, forKey: kCIInputImageKey)
                noiseFilter.setValue(noiseValue, forKey: "inputNoiseLevel")
                ciImage = noiseFilter.outputImage ?? ciImage
            }
            
            // saturation: 채도
            let saturationValue = value(for: .saturation, in: values)
            if !isNeutral(saturationValue, for: .saturation),
               let saturationFilter = CIFilter(name: "CIColorControls") {
                saturationFilter.setValue(ciImage, forKey: kCIInputImageKey)
                saturationFilter.setValue(saturationValue, forKey: kCIInputSaturationKey)
                ciImage = saturationFilter.outputImage ?? ciImage
            }

            // shadows: 암부 보정
            let shadowsValue = value(for: .shadows, in: values)
            if !isNeutral(shadowsValue, for: .shadows),
               let shadowFilter = CIFilter(name: "CIHighlightShadowAdjust") {
                shadowFilter.setValue(ciImage, forKey: kCIInputImageKey)
                shadowFilter.setValue(shadowsValue, forKey: "inputShadowAmount")
                ciImage = shadowFilter.outputImage ?? ciImage
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
                    x: 6500 + CGFloat((CGFloat(temperatureValue) * 25)),
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
