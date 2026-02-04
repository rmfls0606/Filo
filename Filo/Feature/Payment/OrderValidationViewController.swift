//
//  OrderValidationViewController.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class OrderValidationViewController: BaseViewController {
    
    private let viewModel: OrderValidationViewModel
  
    init(viewModel: OrderValidationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }


}
