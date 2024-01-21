//
//  Comment.swift
//  immerse
//
//

import Firebase

struct Comment: Identifiable, Codable {
    let id: String
    let postOwnerUid: String
    let commentText: String
    let postId: String
    let timestamp: Timestamp
    let commentOwnerUid: String
    
    var user: User?
}
