//
//  ChatAttachMenuItem.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation

enum ChatAttachMenuItem: CaseIterable {
    case photo
    case file

    var title: String {
        switch self {
        case .photo: return "사진"
        case .file: return "파일"
        }
    }

    var systemImage: String {
        switch self {
        case .photo: return "photo.on.rectangle"
        case .file: return "doc"
        }
    }
}
