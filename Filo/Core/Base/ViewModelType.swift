//
//  ViewModelType.swift
//  Filo
//
//  Created by 이상민 on 12/16/25.
//

import Foundation

protocol ViewModelType{
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
