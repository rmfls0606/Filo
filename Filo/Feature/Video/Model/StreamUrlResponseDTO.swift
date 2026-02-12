//
//  StreamUrlResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation

struct StreamUrlResponseDTO: Decodable {
    let videoId: String
    let streamURL: String
    let qualities: [VideoQualityDTO]
    let subtitles: [VideoSubtitleDTO]

    private enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case streamURL = "stream_url"
        case qualities
        case subtitles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoId = try container.decodeIfPresent(String.self, forKey: .videoId) ?? ""
        streamURL = try container.decodeIfPresent(String.self, forKey: .streamURL) ?? ""
        qualities = try container.decodeIfPresent([VideoQualityDTO].self, forKey: .qualities) ?? []
        subtitles = try container.decodeIfPresent([VideoSubtitleDTO].self, forKey: .subtitles) ?? []
    }
}

struct VideoQualityDTO: Decodable {
    let quality: String
    let url: String

    private enum CodingKeys: String, CodingKey {
        case quality
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        quality = try container.decodeIfPresent(String.self, forKey: .quality) ?? ""
        url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    }
}

struct VideoSubtitleDTO: Decodable {
    let language: String
    let name: String
    let isDefault: Bool
    let url: String

    private enum CodingKeys: String, CodingKey {
        case language
        case name
        case isDefault = "is_default"
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(String.self, forKey: .language) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    }
}

struct VideoLikeStatus: Decodable {
    let likeStatus: Bool

    private enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
