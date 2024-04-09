//
//  FeedViewModel.swift
//  immerse
//
//

import SwiftUI
import FirebaseAuth
import AVFoundation

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var isLoading = false
    @Published var showEmptyView = false
    @Published var nextPlayer: AVPlayer? = nil
    @Published var preloadedPlayers: [String: AVPlayer] = [:]
    
    private let feedService: FeedService
    private let postService: PostService
    var isContainedInTabBar = true
    var onPostsRefreshed: (() -> Void)?

    init(feedService: FeedService, postService: PostService, posts: [Post] = []) {
        self.feedService = feedService
        self.postService = postService
        self.posts = posts
        self.isContainedInTabBar = posts.isEmpty
        
        Task { await fetchPosts() }
    }
    
    func fetchPosts() async {
        isLoading = true
        
        do {
            if posts.isEmpty {
                let fetchedPosts = try await feedService.fetchPosts()
                posts = fetchedPosts
                posts.shuffle() // Randomly shuffle the order of posts
            }
            isLoading = false
            showEmptyView = posts.isEmpty
            await checkIfUserLikedPosts()
            await checkIfUserFlaggedPosts()
            await checkIfUserRatedPosts()
            await checkIfPostOwnersAreBlocked()
        } catch {
            isLoading = false
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
    }
    
    func refreshFeed() async {
        posts.removeAll()
        isLoading = true
        
        do {
            posts = try await feedService.fetchPosts()
            posts.shuffle()
            isLoading = false
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.checkIfUserLikedPosts()
                }
                group.addTask {
                    await self.checkIfUserFlaggedPosts()
                }
                group.addTask {
                    await self.checkIfUserRatedPosts()
                }
                group.addTask {
                    await self.checkIfPostOwnersAreBlocked()
                }
            }
        } catch {
            isLoading = false
            print("DEBUG: Failed to refresh posts with error: \(error.localizedDescription)")
        }
    }
    
    func checkIfPostOwnersAreBlocked() async {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        
        let blockedUsersRef = FirestoreConstants.UserCollection.document(currentUserUid).collection("blocked-users")
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<posts.count {
                group.addTask {
                    let ownerUid = await self.posts[i].ownerUid
                    
                    let document = try? await blockedUsersRef.document(ownerUid).getDocument()
                    
                    if let isBlocked = document?.exists {
                        await MainActor.run {
                            self.posts[i].isOwnerBlocked = isBlocked
                        }
                    }
                }
            }
        }
    }
    
    func refreshVideo() async {
        posts.removeFirst()
        isLoading = true
        
        do {
            posts = try await feedService.fetchPosts()
            isLoading = false
            await checkIfUserLikedPosts()
            await checkIfUserFlaggedPosts()
        } catch {
            isLoading = false
            print("DEBUG: Failed to refresh posts with error: \(error.localizedDescription)")
        }
    }
    
    func preloadNextVideos(currentIndex: Int) {
            let preloadCount = 2
            let startIndex = currentIndex + 1
            let endIndex = min(startIndex + preloadCount, posts.count)

            for index in startIndex..<endIndex {
                let post = posts[index]
                let playerItem = AVPlayerItem(url: URL(string: post.videoUrl)!)
                playerItem.preferredForwardBufferDuration = TimeInterval(5)
                playerItem.preferredPeakBitRate = 5000000

                let player = AVPlayer(playerItem: playerItem)
                preloadedPlayers[post.id] = player
            }
        }
}

// MARK: - Likes

extension FeedViewModel {
    func like(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].didLike = true
        posts[index].likes += 1
                
        do {
            try await postService.likePost(post)
        } catch {
            print("DEBUG: Failed to like post with error \(error.localizedDescription)")
            posts[index].didLike = false
            posts[index].likes -= 1
        }
    }
    
    func unlike(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].didLike = false
        posts[index].likes -= 1
                
        do {
            try await postService.unlikePost(post)
        } catch {
            print("DEBUG: Failed to unlike post with error \(error.localizedDescription)")
            posts[index].didLike = true
            posts[index].likes += 1
        }
    }
    
    func checkIfUserLikedPosts() async {
        guard !posts.isEmpty else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<posts.count {
                group.addTask {
                    do {
                        let post = await self.posts[i]
                        let didLike = try await self.postService.checkIfUserLikedPost(post)
                        
                        await MainActor.run {
                            self.posts[i].didLike = didLike
                        }
                    } catch {
                        print("DEBUG: Failed to check if user liked post")
                    }
                }
            }
        }
    }
    
    func deletePost(_ post: Post) async {
        do {
            try await postService.deletePost(post.id)
            await MainActor.run {
                if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                    self.posts.remove(at: index)
                }
            }
        } catch {
            print("DEBUG: Failed to delete post with error \(error.localizedDescription)")
        }
    }
    
    func flagPost(_ post: Post) async {
            guard let flaggerUid = Auth.auth().currentUser?.uid else { return }
            let flaggedUid = post.ownerUid // Assuming `ownerUid` is a property of `Post`
            
            do {
                try await postService.flagPost(post.id, flaggerUid: flaggerUid, flaggedUid: flaggedUid)
                print("Post flagged successfully.")
            } catch {
                print("Error flagging post: \(error.localizedDescription)")
            }
        }
    
    func toggleFlagForPost(_ post: Post) async {
            guard let flaggerUid = Auth.auth().currentUser?.uid, var index = posts.firstIndex(where: { $0.id == post.id }) else { return }
            
            let isFlagged = await postService.isPostFlaggedByUser(post.id, flaggerUid: flaggerUid)
            
            do {
                if isFlagged {
                    try await postService.unflagPost(post.id, flaggerUid: flaggerUid)
                    posts[index].didFlag = false
                } else {
                    let flaggedUid = post.ownerUid
                    try await postService.flagPost(post.id, flaggerUid: flaggerUid, flaggedUid: flaggedUid)
                    posts[index].didFlag = true
                }
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            } catch {
                print("Error toggling flag on post: \(error.localizedDescription)")
            }
        }
    
    
    func checkIfUserFlaggedPosts() async {
        guard !posts.isEmpty else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<posts.count {
                group.addTask {
                    do {
                        let post = await self.posts[i]
                        let didFlag = await self.postService.isPostFlaggedByUser(post.id, flaggerUid: Auth.auth().currentUser?.uid ?? "")
                        
                        await MainActor.run {
                            self.posts[i].didFlag = didFlag
                        }
                    } catch {
                        print("DEBUG: Failed to check if user flagged post with error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func ratePost(_ post: Post, rating: Int) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        do {
            try await postService.ratePost(post, rating: rating)
            let updatedPost = try await postService.getUpdatedPostData(post)
            posts[index].averageRating = updatedPost.averageRating
            posts[index].ratings = updatedPost.ratings
        } catch {
            print("DEBUG: Failed to rate post with error \(error.localizedDescription)")
            // Revert the userRating to the previous value if the rating update fails
            posts[index].userRating = post.userRating
        }
    }
    
    func removePostRating(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        do {
            try await postService.removePostRating(post)
            let updatedPost = try await postService.getUpdatedPostData(post)
            posts[index].averageRating = updatedPost.averageRating
            posts[index].ratings = updatedPost.ratings
        } catch {
            print("DEBUG: Failed to remove post rating with error \(error.localizedDescription)")
            // Revert the userRating to the previous value if the rating removal fails
            posts[index].userRating = post.userRating
        }
    }
    
    func checkIfUserRatedPosts() async {
        guard !posts.isEmpty else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<posts.count {
                group.addTask {
                    do {
                        let post = await self.posts[i]
                        let userRating = try await self.postService.checkIfUserRatedPost(post)
                        
                        await MainActor.run {
                            self.posts[i].userRating = userRating
                        }
                    } catch {
                        print("DEBUG: Failed to check if user rated post with error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
