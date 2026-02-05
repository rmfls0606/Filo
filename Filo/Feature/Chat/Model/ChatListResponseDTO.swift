//
//  ChatListResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Foundation

//채팅내역 목록 조회
struct ChatListResponseDTO: Decodable, Sendable{
    let data: [ChatResponseDTO]
}

//파일 업로드 응답 값 - 서버에 올릴 파일 이름
struct ChatFileResponseDTO: Decodable, Sendable{
    let files: [String]
}
