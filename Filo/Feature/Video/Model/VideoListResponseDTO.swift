//
//  VideoListResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation

struct VideoListResponseDTO: Decodable {
    let data: [VideoResponseDTO]
    let nextCursor: String?

    private enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct VideoResponseDTO: Decodable {
    let videoId: String
    let fileName: String
    let title: String
    let description: String
    let duration: String
    let thumbnailURL: String
    let availableQualities: [String]
    let viewCount: Int
    let likeCount: Int
    let isLiked: Bool
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case fileName = "file_name"
        case title
        case description
        case duration
        case thumbnailURL = "thumbnail_url"
        case availableQualities = "available_qualities"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case isLiked = "is_liked"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        videoId = try container.decode(String.self, forKey: .videoId)
        fileName = try container.decode(String.self, forKey: .fileName)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        thumbnailURL = try container.decode(String.self, forKey: .thumbnailURL)
        availableQualities = try container.decode([String].self, forKey: .availableQualities)
        viewCount = try container.decode(Int.self, forKey: .viewCount)
        likeCount = try container.decode(Int.self, forKey: .likeCount)
        isLiked = try container.decode(Bool.self, forKey: .isLiked)
        createdAt = (try? container.decode(String.self, forKey: .createdAt)) ?? ""

        if let durationString = try? container.decode(String.self, forKey: .duration) {
            duration = durationString
        } else if let durationInt = try? container.decode(Int.self, forKey: .duration) {
            duration = String(durationInt)
        } else if let durationDouble = try? container.decode(Double.self, forKey: .duration) {
            let isInteger = durationDouble.truncatingRemainder(dividingBy: 1) == 0
            duration = isInteger ? String(Int(durationDouble)) : String(durationDouble)
        } else {
            duration = "0"
        }
    }
}
