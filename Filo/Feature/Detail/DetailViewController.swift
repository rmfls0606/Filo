//
//  DetailViewController.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class DetailViewController: BaseViewController {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    override var prefersCustomTabBarHidden: Bool{
        return true
    }
    
    //MARK: - UI
    private let detailScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private let detailStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    
    private let filterImageContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let filterImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .orange
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
    }()
    
    private let coinStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        view.alignment = .bottom
        return view
    }()
    
    private let coinLabel: UILabel = {
        let label = UILabel()
        label.text = "2000".formattedDecimal() //수정
        label.font = .Mulggeol.title1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let coinUnitLabel: UILabel = {
        let label = UILabel()
        label.text = "Coin"
        label.font = .Mulggeol.body1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let filterInfoContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let filterInfoStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .fillEqually
        view.alignment = .center
        return view
    }()
    
    let viewModel: DetailViewModel
    
    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func configureHierarchy() {
        view.addSubview(detailScrollView)
        detailScrollView.addSubview(detailStackView)
        detailStackView.addArrangedSubview(filterImageContainer)
        filterImageContainer.addSubview(filterImageView)
        
        detailStackView.addArrangedSubview(dividerView)
        
        detailStackView.addArrangedSubview(coinStackView)
        coinStackView.addArrangedSubview(coinLabel)
        coinStackView.addArrangedSubview(coinUnitLabel)
        
        detailStackView.addArrangedSubview(filterInfoContainer)
        filterInfoContainer.addSubview(filterInfoStackView)
        filterInfoStackView.addArrangedSubview(makeFilterInfoBoxView(title: "다운로드", count: 100000000))
        filterInfoStackView.addArrangedSubview(makeFilterInfoBoxView(title: "찜하기", count: 800))
    }
    
    override func configureLayout() {
        detailScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        detailStackView.snp.makeConstraints { make in
            make.height.equalTo(detailScrollView.contentLayoutGuide)
            make.width.equalTo(detailScrollView.frameLayoutGuide)
        }
        
        filterImageContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
        }
        
        filterImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(filterImageView.snp.width)
            make.bottom.equalToSuperview() //수정해야함
        }
        
        dividerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }
        
        coinStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        coinUnitLabel.snp.makeConstraints { make in
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        filterInfoContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        filterInfoStackView.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
    }
    
    override func configureView() {
        navigationItem.title = "청록새록" //수정
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .likeEmpty)
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .chevron)
        navigationItem.leftBarButtonItem?.tintColor = GrayStyle.gray75.color
    }
    
    override func configureBind() {}
    
    private func makeFilterInfoBoxView(title: String, count: Int = 0) -> UIView{
        let infoContainer: UIView = {
            let view = UIView()
            view.backgroundColor = Brand.blackTurquoise.color
            view.layer.cornerRadius = 12
            return view
        }()
        
        let infoStackView: UIStackView = {
            let view = UIStackView()
            view.axis = .vertical
            view.spacing = 4
            view.alignment = .center
            return view
        }()
        
        let contentTitleLabel: UILabel = {
            let label = UILabel()
            label.text = title
            label.font = .Pretendard.caption1
            label.textColor = GrayStyle.gray75.color
            return label
        }()
        
        let contentCountLabel: UILabel = {
            let label = UILabel()
            label.text = formattedCount(count)
            label.font = .Pretendard.title1
            label.textColor = GrayStyle.gray30.color
            return label
        }()
        
        infoContainer.addSubview(infoStackView)
        infoStackView.addArrangedSubview(contentTitleLabel)
        infoStackView.addArrangedSubview(contentCountLabel)

        infoStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        return infoContainer
    }

    private func formattedCount(_ count: Int) -> String {
        if count <= 1_000 {
            return "\(count)"
        } else if count < 10_000 {
            let prefix = String(count).prefix(2)
            return "\(prefix)00+"
        } else if count < 100_000_000 {
            let man = count / 10_000
            return "\(man)만+"
        } else if count < 1_000_000_000_000 {
            let eok = count / 100_000_000
            return "\(eok)억+"
        } else {
            let jo = count / 1_000_000_000_000
            return "\(jo)조+"
        }
    }
}
