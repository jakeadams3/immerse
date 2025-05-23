//
//  UploadPostService.swift
//  immerse
//
//

import Foundation
import Firebase

struct UploadPostService {
    func uploadPost(caption: String, videoUrlString: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = FirestoreConstants.PostsCollection.document()
        
        do {
            // No need to re-upload to storage, as we assume the URL is already pointing to Cloudflare R2
            let videoUrl = videoUrlString // Directly use the R2 video URL
            
            let post = Post(
                id: ref.documentID,
                videoUrl: videoUrl, // Use the Cloudflare R2 URL
                ownerUid: uid,
                caption: caption,
                likes: 0,
                commentCount: 0,
                saveCount: 0,
                shareCount: 0,
                views: 0,
                thumbnailUrl: "", // This will be updated asynchronously
                timestamp: Timestamp()
            )

            guard let postData = try? Firestore.Encoder().encode(post) else { return }
            try await ref.setData(postData)
            // Assuming `updateThumbnailUrl` correctly handles thumbnail generation and upload
            async let _ = try updateThumbnailUrl(fromVideoUrl: videoUrl, postId: ref.documentID)
        } catch {
            print("DEBUG: Failed to upload post with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateThumbnailUrl(fromVideoUrl videoUrl: String, postId: String) async throws {
        do {
            guard let image = await MediaHelpers.generateThumbnail(path: videoUrl) else { return }
            guard let thumbnailUrl = try await ImageUploader.uploadImage(image: image, type: .post) else { return }
            try await FirestoreConstants.PostsCollection.document(postId).updateData([
                "thumbnailUrl": thumbnailUrl
            ])
        } catch {
            throw error
        }
    }
}
