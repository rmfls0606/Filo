//
//  BannerListResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Foundation

struct BannerListResponseDTO: Decodable, Sendable{
    let data: [BannerDTO]
}

struct BannerDTO: Decodable, Sendable{
    let name: String
    let imageUrl: String
    let payload: BannerPayload
}

struct BannerPayload: Decodable, Sendable{
    let type: String
    let value: String
}

extension BannerListResponseDTO{
    func toEntity() -> BannerListResponseEntity{
        return BannerListResponseEntity(data: data)
    }
}
