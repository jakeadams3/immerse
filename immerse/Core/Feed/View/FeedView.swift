//
//  FeedView.swift
//  immerse
//
//

import SwiftUI
import AVKit

struct FeedView: View {
    @Binding var player: AVPlayer
    @StateObject var viewModel: FeedViewModel
    @State private var scrollPosition: String?
    
    init(player: Binding<AVPlayer>, posts: [Post] = []) {
            self._player = player
            
            let viewModel = FeedViewModel(feedService: FeedService(),
                                          postService: PostService(),
                                          posts: posts)
            self._viewModel = StateObject(wrappedValue: viewModel)
            
            // Set the closure to update the player when posts are refreshed
            viewModel.onPostsRefreshed = { [weak viewModel] in
                if let firstPost = viewModel?.posts.first {
                    player.wrappedValue.replaceCurrentItem(with: AVPlayerItem(url: URL(string: firstPost.videoUrl)!))
                }
            }
        }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach($viewModel.posts) { post in
                            FeedCell(post: post, player: player, viewModel: viewModel)
                                .id(post.id)
                                .onAppear { playInitialVideoIfNecessary(forPost: post.wrappedValue) }
                                
                        }
                    }
                    .scrollTargetLayout()
                }
                
                Button {
                    Task { await viewModel.refreshFeed() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .imageScale(.large)
                        .foregroundStyle(.black)
                        .shadow(radius: 4)
                        .padding(32)
                }
            }
            .background(.black)
            .onAppear { player.play() }
            .onDisappear { player.pause() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.showEmptyView {
                    ContentUnavailableView("No posts to show", systemImage: "eye.slash")
                        .foregroundStyle(.white)
                }
            }
            .scrollPosition(id: $scrollPosition)
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()
            .navigationDestination(for: User.self, destination: { user in
                ProfileView(user: user)
            })
            .onChange(of: scrollPosition, { oldValue, newValue in
                playVideoOnChangeOfScrollPosition(postId: newValue)
            })
        }
    }
    
    func playInitialVideoIfNecessary(forPost post: Post) {
        guard
            scrollPosition == nil,
            let post = viewModel.posts.first,
            player.currentItem == nil else { return }
        
        player.replaceCurrentItem(with: AVPlayerItem(url: URL(string: post.videoUrl)!))
    }
    
    func playVideoOnChangeOfScrollPosition(postId: String?) {
        guard let currentPost = viewModel.posts.first(where: {$0.id == postId }) else {
            print("playVideoOnChangeOfScrollPosition: No post found for id \(postId ?? "nil")")
            return
        }
        
        print("playVideoOnChangeOfScrollPosition: Preparing to replace player item for post id \(postId ?? "nil")")
        player.replaceCurrentItem(with: nil)
        let playerItem = AVPlayerItem(url: URL(string: currentPost.videoUrl)!)
        player.replaceCurrentItem(with: playerItem)
        print("playVideoOnChangeOfScrollPosition: Player item replaced for post id \(postId ?? "nil")")
    }
}

#Preview {
    FeedView(player: .constant(AVPlayer()), posts: DeveloperPreview.posts)
}
