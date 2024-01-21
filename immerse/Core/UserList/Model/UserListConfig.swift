//
//  UserListConfig.swift
//  immerse
//
//

import Foundation

enum UserListConfig: Hashable {
    case blocked
    case followers(String)
    case following(String)
    case likes(String)
    case search
    case newMessage
    
    var navigationTitle: String {
        switch self {
        case .blocked: return "Blocked Users"
        case .followers: return "Followers"
        case .following: return "Following"
        case .likes: return "Likes"
        case .search: return "Explore"
        case .newMessage: return "NewMessage"
        }
    }
}
