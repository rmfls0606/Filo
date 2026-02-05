//
//  BannerWebViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Foundation
import RxSwift
import RxCocoa

final class BannerWebViewModel: ViewModelType{
    private let banner: BannerDTO
    
    init(banner: BannerDTO) {
        self.banner = banner
    }
    
    private let disposeBag = DisposeBag()
    
    struct Input{
        
    }
    
    struct Output{
        let bannerData: Driver<BannerDTO>
    }
    
    func transform(input: Input) -> Output {
        let bannerDataRelay = BehaviorRelay<BannerDTO>(value: banner)
        
        return Output(
            bannerData: bannerDataRelay.asDriver()
        )
    }
}
