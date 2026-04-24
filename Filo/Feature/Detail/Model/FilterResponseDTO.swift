//
//  FilterResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import Foundation

struct FilterResponseDTO: Decodable, Sendable{
    let filterId: String
    let category: String
    let title: String
    let description: String
    let files: [String]
    let price: Int
    let creator: UserInfoResponseDTO
    let photoMetadata: PhotoMetadataDTO?
    let filterValues: FilterValuesDTO
    let isLiked: Bool
    let isDownloaded: Bool
    let likeCount: Int
    let buyerCount: Int
    let comments: [FilterCommentResponseDTO]
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case filterId = "filter_id"
        case category
        case title
        case description
        case files
        case price
        case creator
        case photoMetadata
        case filterValues
        case isLiked = "is_liked"
        case isDownloaded = "is_downloaded"
        case likeCount = "like_count"
        case buyerCount = "buyer_count"
        case comments
        case createdAt
        case updatedAt
    }
}

struct PhotoMetadataDTO: Decodable, Sendable{
    let camera: String?
    let lensInfo: String?
    let focalLength: Double?
    let aperture: Double?
    let iso: Int?
    let shutterSpeed: String?
    let pixelWidth: Int?
    let pixelHeight: Int?
    let fileSize: Double?
    let format: String?
    let dateTimeOriginal: String?
    let latitude: Double?
    let longitude: Double?
    
    private enum CodingKeys: String, CodingKey {
        case camera
        case lensInfo = "lens_info"
        case focalLength = "focal_length"
        case aperture
        case iso
        case shutterSpeed = "shutter_speed"
        case pixelWidth = "pixel_width"
        case pixelHeight = "pixel_height"
        case fileSize = "file_size"
        case format
        case dateTimeOriginal = "date_time_original"
        case latitude
        case longitude
    }
}

struct FilterValuesDTO: Decodable, Sendable{
    let brightness: Double?
    let exposure: Double?
    let contrast: Double?
    let saturation: Double?
    let sharpness: Double?
    let blur: Double?
    let vignette: Double?
    let noiseReduction: Double?
    let highlights: Double?
    let shadows: Double?
    let temperature: Double?
    let blackPoint: Double?
    
    private enum CodingKeys: String, CodingKey {
        case brightness
        case exposure
        case contrast
        case saturation
        case sharpness
        case blur
        case vignette
        case noiseReduction = "noise_reduction"
        case highlights
        case shadows
        case temperature
        case blackPoint = "black_point"
    }
}

extension FilterValuesDTO {
    func text(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f", value)
    }

    private func temperatureText(_ value: Double?) -> String {
        guard let value else { return "-" }
        if value >= 1000.0 {
            return String(format: "%.0fK", value)
        }
        return String(format: "%.1f", value)
    }

    private func centeredText(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f", value - 1.0)
    }
    
    func toEntity() -> [FilterValuesEntity] {
        return [
            FilterValuesEntity(iconName: "brightness", valueText: text(brightness)),
            FilterValuesEntity(iconName: "exposure", valueText: text(exposure)),
            FilterValuesEntity(iconName: "contrast", valueText: centeredText(contrast)),
            FilterValuesEntity(iconName: "saturation", valueText: centeredText(saturation)),
            FilterValuesEntity(iconName: "sharpness", valueText: text(sharpness)),
            FilterValuesEntity(iconName: "blur", valueText: text(blur)),
            FilterValuesEntity(iconName: "vignette", valueText: text(vignette)),
            FilterValuesEntity(iconName: "noise", valueText: text(noiseReduction)),
            FilterValuesEntity(iconName: "highlights", valueText: centeredText(highlights)),
            FilterValuesEntity(iconName: "shadows", valueText: text(shadows)),
            FilterValuesEntity(iconName: "temperature", valueText: temperatureText(temperature)),
            FilterValuesEntity(iconName: "blackPoint", valueText: text(blackPoint))
        ]
    }

    func toFilterImagePropsEntity() -> FilterImagePropsEntity {
        return FilterImagePropsEntity(
            blackPoint: blackPoint ?? 0,
            blur: blur ?? 0,
            brightness: brightness ?? 0,
            contrast: contrast ?? 1,
            exposure: exposure ?? 0,
            highlights: highlights ?? 1,
            noise: noiseReduction ?? 0,
            saturation: saturation ?? 1,
            shadows: shadows ?? 0,
            sharpness: sharpness ?? 0,
            temperature: incomingTemperatureToUI(temperature),
            vignette: vignette ?? 0
        )
    }

    private func incomingTemperatureToUI(_ value: Double?) -> Double {
        guard let value else { return 0.0 }
        if value >= 1000.0 {
            let ui = (value - 6500.0) / 25.0
            return min(max(ui, -100.0), 100.0)
        }
        return min(max(value, -100.0), 100.0)
    }
}

struct FilterCommentResponseDTO: Decodable, Sendable{
    let commentId: String
    let content: String
    let createdAt: String
    let creator: UserInfoResponseDTO
    let replies: [CommentReply]
    
    private enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
        case replies
    }
}

struct CommentReply: Decodable, Sendable{
    let commentId: String
    let content: String
    let createdAt: String
    let creator: UserInfoResponseDTO
    
    private enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
    }
}
