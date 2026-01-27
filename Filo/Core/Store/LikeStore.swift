//
//  LikeStore.swift
//  Filo
//
//  Created by 이상민 on 01/24/26.
//

import Foundation
import RxSwift
import RxCocoa

final class LikeStore {
    static let shared = LikeStore()
    private init() {}
    
    private let likedIdsRelay = BehaviorRelay<Set<String>>(value: [])
    private let likeCountsRelay = BehaviorRelay<[String: Int]>(value: [:])
    
    var likedIds: Observable<Set<String>> {
        return likedIdsRelay.asObservable()
    }

    var likeCounts: Observable<[String: Int]> {
        return likeCountsRelay.asObservable()
    }
    
    func setLiked(id: String, liked: Bool, count: Int) {
        var ids = likedIdsRelay.value
        if liked{
            ids.insert(id)
        }else{
            ids.remove(id)
        }
        
        likedIdsRelay.accept(ids)
        
        var counts = likeCountsRelay.value
        counts[id] = count
        likeCountsRelay.accept(counts)
    }
    
    func isLiked(id: String) -> Bool {
        likedIdsRelay.value.contains(id)
    }
    
    func likeCount(id: String) -> Int? {
        likeCountsRelay.value[id]
    }
}
