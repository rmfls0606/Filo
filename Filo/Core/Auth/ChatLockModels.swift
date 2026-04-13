//
//  ChatLockModels.swift
//  Filo
//
//  Created by Codex on 4/13/26.
//

import Foundation

enum ChatLockLeadingAction: Equatable {
    case biometric
    case cancel
    case empty
}

enum ChatLockScreenItem {
    case digit(String)
    case biometric
    case cancel
    case delete
    case empty
}

struct ChatLockAlert {
    let title: String
    let message: String
}
