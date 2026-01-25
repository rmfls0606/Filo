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
}

struct CreateFilterMetadata: Encodable{
    let camera: String?
    let lens_info: String?
    let focal_length: Double?
    let aperture: Double?
    let iso: Int?
    let shutterSpeed: String?
    let pixel_width: Int?
    let pixel_height: Int?
    let file_size: Double?
    let format: String?
    let date_title_original: String
    let latitude: Double?
    let longitude: Double?

    private enum CodingKeys: String, CodingKey {
        case camera
        case lens_info
        case focal_length
        case aperture
        case iso
        case shutterSpeed = "shutter_speed"
        case pixel_width
        case pixel_height
        case file_size
        case format
        case date_title_original
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
