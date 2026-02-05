//
//  ChatAttachmentItem.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation

struct ChatAttachmentItem: Hashable, Sendable {
    let id: UUID
    let data: Data
    let fileName: String
    let mimeType: String
    let isImage: Bool

    init(data: Data, fileName: String, mimeType: String, isImage: Bool) {
        self.id = UUID()
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
        self.isImage = isImage
    }
}
