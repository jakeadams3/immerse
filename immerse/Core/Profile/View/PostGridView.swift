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
        GeometryReader { geometry in
            let width = (geometry.size.width / 3) - 2
            LazyVGrid(columns: items, spacing: 2) {
                ForEach(viewModel.posts) { post in
                    KFImage(URL(string: post.thumbnailUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: 450)
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPost = post }
                }
            }
            .fullScreenCover(item: $selectedPost) { post in
                FeedView(player: $player, posts: [post])
                    .overlay(
                        HStack {
                            Button(action: {
                                selectedPost = nil // This will dismiss the full-screen cover
                            }) {
                                Image(systemName: "arrow.backward")
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Circle().fill(Color.white.opacity(0.5)))
                            }
                            Spacer()
                        }
                            .padding(.top)
                            .padding(.horizontal)
                        , alignment: .topLeading
                    )
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
