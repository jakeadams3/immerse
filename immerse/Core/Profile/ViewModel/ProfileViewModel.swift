//
//  ProfileViewModel.swift
//  immerse
//
//

import AVFoundation
import SwiftUI
import Firebase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var user: User
    @Published var isBlocked: Bool = false
    @Published var likedPosts = [Post]()
    @Published var isLoadingLikedPosts = false
    
    private let userService: UserService
    private let postService: PostService
    private var didCompleteFollowCheck = false
    private var didCompleteStatsFetch = false
    
    init(user: User, userService: UserService, postService: PostService) {
        self.user = user
        self.userService = userService
        self.postService = postService
    }
}

// MARK: - Following

extension ProfileViewModel {
    func follow() {
        Task {
            try await userService.follow(uid: user.id)
            user.isFollowed = true
            user.stats.followers += 1

            NotificationManager.shared.uploadFollowNotification(toUid: user.id)
        }
    }
    
    func unfollow() {
        Task {
            try await userService.unfollow(uid: user.id)
            user.isFollowed = false
            user.stats.followers -= 1
        }
    }
    
    func checkIfUserIsFollowed() async {
        guard !user.isCurrentUser, !didCompleteFollowCheck else { return }
        self.user.isFollowed = await userService.checkIfUserIsFollowed(uid: user.id)
        self.didCompleteFollowCheck = true
    }
}

// MARK: - Stats

extension ProfileViewModel {
    func fetchUserStats() async {
        guard !didCompleteStatsFetch else { return }
        
        do {
            user.stats = try await userService.fetchUserStats(uid: user.id)
            didCompleteStatsFetch = true
        } catch {
            print("DEBUG: Failed to fetch user stats with error \(error.localizedDescription)")
        }
    }
}

// MARK: - Posts

extension ProfileViewModel {
    func fetchUserPosts() async {
        do {
            var fetchedPosts = try await postService.fetchUserPosts(user: user)
            // Sort fetchedPosts by timestamp in descending order (newest first)
            fetchedPosts.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            self.posts = fetchedPosts
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
    
    func fetchLikedPosts() async {
        isLoadingLikedPosts = true
        
        do {
            let fetchedPosts = try await postService.fetchLikedPosts(user: user)
            self.likedPosts = fetchedPosts
        } catch {
            print("DEBUG: Failed to fetch liked posts with error: \(error.localizedDescription)")
        }
        
        isLoadingLikedPosts = false
    }
}

extension ProfileViewModel {
    func blockUser() async {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let blockedUid = user.id

        let blockedUsersRef = FirestoreConstants.UserCollection.document(currentUserUid).collection("blocked-users")
        
        do {
            try await blockedUsersRef.document(blockedUid).setData([:])
            DispatchQueue.main.async {
                self.isBlocked = true
            }
        } catch let error {
            print("Failed to block user: \(error.localizedDescription)")
        }
    }
    
    func unblockUser() async {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let blockedUid = user.id

        let blockedUsersRef = FirestoreConstants.UserCollection.document(currentUserUid).collection("blocked-users")
        
        do {
            try await blockedUsersRef.document(blockedUid).delete()
            DispatchQueue.main.async {
                self.isBlocked = false
            }
        } catch let error {
            print("Failed to unblock user: \(error.localizedDescription)")
        }
    }
    
    func checkBlocked() async {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        let checkedUid = user.id

        let blockedUsersRef = FirestoreConstants.UserCollection.document(currentUserUid).collection("blocked-users")

        do {
            let document = try await blockedUsersRef.document(checkedUid).getDocument()
            DispatchQueue.main.async {
                self.isBlocked = document.exists
            }
        } catch let error {
            print("Failed to check if user is blocked: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isBlocked = false
            }
        }
    }
}
