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
    struct Input { }
    
    struct Output {
        let imageData: Driver<Data>
        let filterProps: Driver<[FilterProps]>
    }
    
    private let imageRelay: BehaviorRelay<Data>
    
    init(imageData: Data) {
        self.imageRelay = BehaviorRelay(value: imageData)
    }
    
    func transform(input: Input) -> Output {
        let filterPropsRelay = BehaviorRelay<[FilterProps]>(
            value: FilterProps.allCases
        )
        
        return Output(
            imageData: imageRelay.asDriver(),
            filterProps: filterPropsRelay.asDriver()
        )
    }
}
