//
//  CreateFilterRequestBody.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import Foundation

struct CreateFilterRequestBody: Encodable{
    let category: String
    let title: String
    let price: Int
    let description: String
    let files: [String]
    let photo_metadata: CreateFilterMetadata
    let filter_values: CreateFilterValues

    private enum CodingKeys: String, CodingKey {
        case category
        case title
        case price
        case description
        case files
        case photo_metadata = "photo_metadata"
        case filter_values = "filter_values"
    }
}

struct CreateFilterMetadata: Encodable{
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

struct CreateFilterValues: Encodable{
    let brightness: Double?
    let exposure: Double?
    let contrast: Double?
    let saturation: Double?
    let sharpness: Double?
    let blur: Double?
    let vignette: Double?
    let noise_reduction: Double?
    let highlights: Double?
    let shadows: Double
    let temperature: Double?
    let black_point: Double?
}

extension Encodable {
    func asParameters() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: data, options: []),
              let params = object as? [String: Any] else {
            return nil
        }
        return params
    }
}
