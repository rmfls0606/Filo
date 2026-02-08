//
//  ProfileImageResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation

struct ProfileImageResponseDTO: Decodable, Sendable {
    let profileImage: String
    
    private enum CodingKeys: String, CodingKey {
        case profileImage
        case profile
        case files
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(String.self, forKey: .profileImage) {
            profileImage = value
            return
        }
        if let value = try? container.decode(String.self, forKey: .profile) {
            profileImage = value
            return
        }
        if let files = try? container.decode([String].self, forKey: .files),
           let first = files.first {
            profileImage = first
            return
        }
        throw DecodingError.dataCorruptedError(forKey: .profileImage,
                                               in: container,
                                               debugDescription: "Missing profile image path")
    }
}
