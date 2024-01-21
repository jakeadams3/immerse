//
//  FeedViewModel.swift
//  immerse
//
//

import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var isLoading = false
    @Published var showEmptyView = false
    
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
                posts = try await feedService.fetchPosts()
                posts.shuffle()
            }
            isLoading = false
            showEmptyView = posts.isEmpty
            await checkIfUserLikedPosts()
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
                onPostsRefreshed?()  // Call the closure after successfully refreshing posts
                await checkIfUserLikedPosts()
            } catch {
                isLoading = false
                print("DEBUG: Failed to refresh posts with error: \(error.localizedDescription)")
            }
        }
    
    func refreshVideo() async {
        posts.removeFirst()
        isLoading = true
        
        do {
            posts = try await feedService.fetchPosts()
            isLoading = false
            await checkIfUserLikedPosts()
        } catch {
            isLoading = false
            print("DEBUG: Failed to refresh posts with error: \(error.localizedDescription)")
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
        var copy = posts
        
        for i in 0 ..< copy.count {
            do {
                let post = copy[i]
                let didLike = try await self.postService.checkIfUserLikedPost(post)
                
                if didLike {
                    copy[i].didLike = didLike
                }
                
            } catch {
                print("DEBUG: Failed to check if user liked post")
            }
        }
        
        posts = copy
    }
}
