//
//  PostService.swift
//  immerse
//
//

import Firebase

class PostService {
    func fetchPost(postId: String) async throws -> Post {
        return try await FirestoreConstants
            .PostsCollection
            .document(postId)
            .getDocument(as: Post.self)
    }
    
    func fetchUserPosts(user: User) async throws -> [Post] {
        var posts = try await FirestoreConstants
            .PostsCollection
            .whereField("ownerUid", isEqualTo: user.id)
            .getDocuments(as: Post.self)
        
        for i in 0 ..< posts.count {
            posts[i].user = user
        }
        
        return posts
    }
}

// MARK: - Likes

extension PostService {
    func likePost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).setData([:])
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).updateData(["likes": post.likes + 1])
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).setData([:])
        
        NotificationManager.shared.uploadLikeNotification(toUid: post.ownerUid, post: post)
    }
    
    func unlikePost(_ post: Post) async throws {
        guard post.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).collection("post-likes").document(uid).delete()
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).delete()
        async let _ = try FirestoreConstants.PostsCollection.document(post.id).updateData(["likes": post.likes - 1])
        
        async let _ = NotificationManager.shared.deleteNotification(toUid: post.ownerUid, type: .like)
    }
    
    func checkIfUserLikedPost(_ post: Post) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
                
        let snapshot = try await FirestoreConstants.UserCollection.document(uid).collection("user-likes").document(post.id).getDocument()
        return snapshot.exists
    }
    
    func deletePost(_ postId: String) async throws {
            // Delete the post document from Firestore
            try await FirestoreConstants.PostsCollection.document(postId).delete()
        }
    
    func flagPost(_ postId: String, flaggerUid: String, flaggedUid: String) async throws {
            let flagRef = FirestoreConstants.FlagsCollection.document(postId)
            
            let flagData: [String: Any] = ["flaggedUid": flaggedUid]
            try await flagRef.setData(flagData, merge: true)
            
            let flaggerRef = flagRef.collection("flaggers").document(flaggerUid)
            let flaggerData: [String: Any] = ["flagged": true]
            try await flaggerRef.setData(flaggerData)
        }
    
    func unflagPost(_ postId: String, flaggerUid: String) async throws {
            let flaggerRef = FirestoreConstants.FlagsCollection.document(postId).collection("flaggers").document(flaggerUid)
            try await flaggerRef.delete()
        }

    func isPostFlaggedByUser(_ postId: String, flaggerUid: String) async -> Bool {
            let flaggerRef = FirestoreConstants.FlagsCollection.document(postId).collection("flaggers").document(flaggerUid)
            let document = try? await flaggerRef.getDocument()
        return document!.exists
        }
}
