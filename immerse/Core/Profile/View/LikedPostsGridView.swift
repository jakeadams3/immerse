//
//  LikedPostsGridView.swift
//  immerse
//
//  Created by Jake Adams on 4/11/24.
//

import SwiftUI
import Kingfisher
import AVKit

struct LikedPostsGridView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var player = AVPlayer()
    @State private var selectedPost: Post?
    
    private let items = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
    ]
    
    var body: some View {
        ScrollView {
            if viewModel.isLoadingLikedPosts {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .padding()
                    .padding(.top, 200)
                    .tint(.white)
            } else {
                LazyVGrid(columns: items, spacing: 2) {
                    ForEach(viewModel.likedPosts) { post in
                        KFImage(URL(string: post.thumbnailUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(height: 450)
                            .clipped()
                            .contentShape(Rectangle())
                            .onTapGesture { selectedPost = post }
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedPost) { post in
            FeedView(posts: [post], showBackButton: true, onBackButtonTapped: {
                selectedPost = nil
            })
            .onDisappear {
                player.replaceCurrentItem(with: nil)
            }
        }
    }
}

#Preview {
    LikedPostsGridView(viewModel: ProfileViewModel(
        user: DeveloperPreview.user,
        userService: UserService(),
        postService: PostService())
    )
}
