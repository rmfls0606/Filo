//
//  BaseViewController.swift
//  Filo
//
//  Created by 이상민 on 12/16/25.
//

import UIKit

class BaseViewController: UIViewController, CustomTabBarVisibilityProtocol {
    var prefersCustomTabBarHidden: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureLayout()
        configureView()
        configureBind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setMainCustomTabBarHidden(prefersCustomTabBarHidden)
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
