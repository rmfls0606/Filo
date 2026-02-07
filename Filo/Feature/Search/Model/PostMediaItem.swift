//
//  PostMediaItem.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit

struct PostMediaItem: Equatable {
    let id: UUID
    let data: Data?
    let fileName: String?
    let mimeType: String?
    let thumbnail: UIImage
    let isVideo: Bool
    let isValid: Bool
}
