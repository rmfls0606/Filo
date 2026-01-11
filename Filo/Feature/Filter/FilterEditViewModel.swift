//
//  FilterEditViewModel.swift
//  Filo
//
//  Created by 이상민 on 12/20/25.
//

import Foundation
import RxSwift
import RxCocoa

final class FilterEditViewModel: ViewModelType {
    struct Input {
        let selectedProp: ControlEvent<FilterPropItem>
    }
    
    struct Output {
        let imageData: Driver<Data>
        let filterProps: Driver<[FilterPropItem]>
        let selectedProp: Driver<FilterProps>
    }
    
    private let imageRelay: BehaviorRelay<Data>
    private let disposeBag = DisposeBag()
    
    init(imageData: Data) {
        self.imageRelay = BehaviorRelay(value: imageData)
    }
    
    func transform(input: Input) -> Output {
        let filterPropsRelay = BehaviorRelay<[FilterPropItem]>(value: [])
        let selectedPropRelay = BehaviorRelay<FilterProps>(value: .brightness)
        
        input.selectedProp
            .map{ $0.prop }
            .bind(to: selectedPropRelay)
            .disposed(by: disposeBag)
        
        selectedPropRelay
            .map { selected in
                FilterProps.allCases.map { prop in
                    FilterPropItem(prop: prop, isSelected: prop == selected)
                }
            }
            .bind(to: filterPropsRelay)
            .disposed(by: disposeBag)
        
        
        return Output(
            imageData: imageRelay.asDriver(),
            filterProps: filterPropsRelay.asDriver(),
            selectedProp: selectedPropRelay.asDriver()
        )
    }
}
