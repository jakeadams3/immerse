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
    
    func fetchLikedPosts(user: User) async throws -> [Post] {
        let likedPostsSnapshot = try await FirestoreConstants
            .UserCollection
            .document(user.id)
            .collection("user-likes")
            .getDocuments()

        var likedPosts: [Post] = []

        for document in likedPostsSnapshot.documents {
            let postId = document.documentID
            if var post = try? await fetchPost(postId: postId) {
                // Fetch the user data associated with the post
                let ownerUid = post.ownerUid
                let user = try await UserService().fetchUser(withUid: ownerUid)
                post.user = user
                likedPosts.append(post)
            }
        }

        return likedPosts
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
    
    func ratePost(_ post: Post, rating: Int) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ratingRef = FirestoreConstants.PostsCollection.document(post.id).collection("star-ratings").document(uid)
        let ratingData: [String: Any] = ["rating": "\(rating)/1"]
        
        try await ratingRef.setData(ratingData)
        
        try await updateAverageRating(for: post)
    }

    func updateAverageRating(for post: Post) async throws {
        let ratingsSnapshot = try await FirestoreConstants.PostsCollection.document(post.id).collection("star-ratings").getDocuments()
        
        let ratingsCount = ratingsSnapshot.documents.count
        let ratingsSum = ratingsSnapshot.documents.reduce(0) { sum, document in
            let rating = document.data()["rating"] as? String ?? "0/1"
            let components = rating.components(separatedBy: "/")
            guard let numerator = Int(components[0]), let denominator = Int(components[1]) else { return sum }
            return sum + numerator
        }
        
        let averageRating = ratingsCount > 0 ? "\(ratingsSum)/\(ratingsCount)" : "0/1"
        
        try await FirestoreConstants.PostsCollection.document(post.id).updateData([
            "averageRating": averageRating,
            "ratings": ratingsCount
        ])
    }

    func removePostRating(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ratingRef = FirestoreConstants.PostsCollection.document(post.id).collection("star-ratings").document(uid)
        
        try await ratingRef.delete()
        try await updateAverageRating(for: post)
    }

    func getAverageRatingForPost(_ post: Post) async -> String {
        let postSnapshot = try? await FirestoreConstants.PostsCollection.document(post.id).getDocument()
        return postSnapshot?.data()?["averageRating"] as? String ?? "0/1"
    }
    
    func getUpdatedPostData(_ post: Post) async throws -> Post {
        let postSnapshot = try await FirestoreConstants.PostsCollection.document(post.id).getDocument()
        
        guard let postData = postSnapshot.data() else {
            throw NSError(domain: "PostService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch updated post data"])
        }
        
        let averageRating = postData["averageRating"] as? String ?? "0/1"
        let ratings = postData["ratings"] as? Int ?? 0
        
        var updatedPost = post
        updatedPost.averageRating = averageRating
        updatedPost.ratings = ratings
        
        return updatedPost
    }
    
    func checkIfUserRatedPost(_ post: Post) async throws -> Int {
        guard let uid = Auth.auth().currentUser?.uid else { return 0 }
        
        let ratingSnapshot = try await FirestoreConstants.PostsCollection.document(post.id).collection("star-ratings").document(uid).getDocument()
        
        if ratingSnapshot.exists {
            let ratingData = ratingSnapshot.data()
            let rating = ratingData?["rating"] as? String ?? "0/1"
            let components = rating.components(separatedBy: "/")
            return Int(components[0]) ?? 0
        }
        
        return 0
    }
}
