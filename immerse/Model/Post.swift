//
//  Post.swift
//  immerse
//
//

import Firebase
import FirebaseFirestoreSwift
import SwiftUI
import AVKit

struct Post: Identifiable, Codable {
    let id: String
    let videoUrl: String
    let ownerUid: String
    let caption: String
    var likes: Int
    var commentCount: Int
    var saveCount: Int
    var shareCount: Int
    var views: Int
    var thumbnailUrl: String
    var timestamp: Timestamp
    var user: User?
    var didLike = false
    var didSave = false
    var didFlag: Bool = false
    var isOwnerBlocked: Bool = false
    var userRating: Int = 0
    var averageRating: String = "0/1"
    var ratings: Int = 0
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.videoUrl = try container.decode(String.self, forKey: .videoUrl)
        self.ownerUid = try container.decode(String.self, forKey: .ownerUid)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.likes = try container.decode(Int.self, forKey: .likes)
        self.commentCount = try container.decode(Int.self, forKey: .commentCount)
        self.saveCount = try container.decode(Int.self, forKey: .saveCount)
        self.shareCount = try container.decode(Int.self, forKey: .shareCount)
        self.views = try container.decode(Int.self, forKey: .views)
        self.thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
        self.timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
        self.user = try container.decodeIfPresent(User.self, forKey: .user)
        self.didLike = try container.decodeIfPresent(Bool.self, forKey: .didLike) ?? false
        self.didSave = try container.decodeIfPresent(Bool.self, forKey: .didSave) ?? false
        self.userRating = try container.decodeIfPresent(Int.self, forKey: .userRating) ?? 0
        self.averageRating = try container.decodeIfPresent(String.self, forKey: .averageRating) ?? "0/1"
        self.ratings = try container.decodeIfPresent(Int.self, forKey: .ratings) ?? 0
    }
    
    init(
        id: String,
        videoUrl: String,
        ownerUid: String,
        caption: String,
        likes: Int,
        commentCount: Int,
        saveCount: Int,
        shareCount: Int,
        views: Int,
        thumbnailUrl: String,
        timestamp: Timestamp,
        user: User? = nil,
        didLike: Bool = false,
        didSave: Bool = false,
        userRating: Int = 0,
        averageRating: String = "0/1",
        ratings: Int = 0
    ) {
        self.id = id
        self.videoUrl = videoUrl
        self.ownerUid = ownerUid
        self.caption = caption
        self.likes = likes
        self.commentCount = commentCount
        self.saveCount = saveCount
        self.shareCount = shareCount
        self.views = views
        self.thumbnailUrl = thumbnailUrl
        self.timestamp = timestamp
        self.user = user
        self.didLike = didLike
        self.didSave = didSave
        self.userRating = userRating
        self.averageRating = averageRating
        self.ratings = ratings
    }
}

extension Post: Hashable { }

extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}
