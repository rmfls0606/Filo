//
//  FilterViewModel.swift
//  Filo
//
//  Created by 이상민 on 12/18/25.
//

import Foundation
import RxSwift
import RxCocoa

final class FilterViewModel: ViewModelType{
    private let disposeBag = DisposeBag()
    
    struct Input{
        let categorySelected: Observable<FilterCategoryType>
        let imageSelected: Observable<Data>
        let editResult: Observable<(Data, FilterImagePropsEntity)>
    }
    
    struct Output{
        let categories: Driver<[FilterCategoryEntity]>
        let currentImageData: Driver<Data?>
        let currentFilterProps: Driver<FilterImagePropsEntity?>
        let originalImageData: Driver<Data?>
        let editEnabled: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let categoriesRelay = BehaviorRelay<[FilterCategoryEntity]>(
            value: FilterCategoryType.allCases.map{
                FilterCategoryEntity(type: $0)
            }
        )
        let imageDataRelay = BehaviorRelay<Data?>(value: nil)
        let originalImageDataRelay = BehaviorRelay<Data?>(value: nil)
        let filterPropsRelay = BehaviorRelay<FilterImagePropsEntity?>(value: nil)
        
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
        
        return Output(
            categories: categoriesRelay.asDriver(),
            currentImageData: imageDataRelay.asDriver(),
            currentFilterProps: filterPropsRelay.asDriver(),
            originalImageData: originalImageDataRelay.asDriver(),
            editEnabled: imageDataRelay
                .map { $0 != nil }
                .asDriver(onErrorJustReturn: false)
        )
    }
}
