//
//  MultipartFile.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import Foundation

struct MultipartFile {
    let data: Data
    let name: String
    let fileName: String
    let mimeType: String
}
