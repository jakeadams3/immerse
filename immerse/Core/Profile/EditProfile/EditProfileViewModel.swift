//
//  EditProfileViewModel.swift
//  immerse
//
//

import SwiftUI
import Firebase

class EditProfileViewModel: ObservableObject {
    
    func uploadProfileImage(_ uiImage: UIImage) async -> String? {
        do {
            async let imageUrl = ImageUploader.uploadImage(image: uiImage, type: .profile)
            try await updateUserProfileImage(withImageUrl: try await imageUrl)
            return try await imageUrl
        } catch {
            print("DEBUG: Failed to update image with error: \(error.localizedDescription)")
            return nil 
        }
    }
    
    func updateUserProfileImage(withImageUrl imageUrl: String?) async throws {
        guard let imageUrl = imageUrl else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        try await FirestoreConstants.UserCollection.document(currentUid).updateData([
            "profileImageUrl": imageUrl
        ])
    }
    
    func updateUserProfile(fullname: String, username: String, bio: String) async throws {
            guard let currentUid = Auth.auth().currentUser?.uid else { return }
            let userData: [String: Any] = [
                "fullname": fullname,
                "username": username,
                "bio": bio
            ]
            try await FirestoreConstants.UserCollection.document(currentUid).updateData(userData)
        }
}
