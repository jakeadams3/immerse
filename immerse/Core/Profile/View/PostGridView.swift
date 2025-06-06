//
//  PostGridView.swift
//  immerse
//
//

import SwiftUI
import Kingfisher
import AVKit

struct PostGridView: View {
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
            LazyVGrid(columns: items, spacing: 2) {
                ForEach(viewModel.posts) { post in
                    KFImage(URL(string: post.thumbnailUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 450)
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPost = post }
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
}

#Preview {
    PostGridView(viewModel: ProfileViewModel(
        user: DeveloperPreview.user,
        userService: UserService(),
        postService: PostService())
    )
}
