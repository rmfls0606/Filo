//
//  BaseViewController.swift
//  Filo
//
//  Created by 이상민 on 12/16/25.
//

import UIKit

class BaseViewController: UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureLayout()
        configureView()
        configureBind()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() { }
    func configureBind() { }
}
