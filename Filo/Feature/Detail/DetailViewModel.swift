//
//  DetailViewModel.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import UIKit
import RxSwift
import RxCocoa

final class DetailViewModel: ViewModelType {
    
    let filterId: String
    
    init(filterId: String) {
        self.filterId = filterId
    }
    
    struct Input{
        
    }
    
    struct Output{
    }
    
    func transform(input: Input) -> Output {
        return Output()
    }
}
