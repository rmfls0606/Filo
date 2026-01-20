//
//  ServerErrorDTO.swift
//  Filo
//
//  Created by 이상민 on 1/21/26.
//

import Foundation

struct ServerErrorDTO: Decodable, Sendable {
    let message: String

    private enum CodingKeys: CodingKey {
        case message
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decode(String.self, forKey: .message)
    }
}
