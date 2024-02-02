//
//  FeedCell.swift
//  immerse
//
//

import SwiftUI
import AVKit

struct FeedCell: View {
    @Binding var post: Post
    var player: AVPlayer
    @ObservedObject var viewModel: FeedViewModel
    @State private var expandCaption = false
    @State private var showComments = false
    @State private var showingDeleteAlert = false
        
    private var didLike: Bool { return post.didLike }
    
    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .containerRelativeFrame([.horizontal, .vertical])
                    
            VStack {
                Spacer()
                
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, .black.opacity(0.15)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.user?.username ?? "")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text(post.caption)
                                .lineLimit(expandCaption ? 50 : 2)
                            
                        }
                        .onTapGesture { withAnimation(.snappy) { expandCaption.toggle() } }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                        
                        Spacer()
                        
                        VStack(spacing: 28) {
                            NavigationLink(value: post.user) {
                                ZStack(alignment: .bottom) {
                                    CircularProfileImageView(user: post.user, size: .medium)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.pink)
                                        .offset(y: 8)
                                }
                            }
                            
                            Button {
                                handleLikeTapped()
                            } label: {
                                FeedCellActionButtonView(imageName: didLike ? "heart.fill" : "heart",
                                                         value: post.likes,
                                                         tintColor: didLike ? .red : .black)
                            }
                            
                            Button {
                                player.pause()
                                showComments.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "ellipsis.bubble", value: post.commentCount)
                            }
                            
                            Button {
                                Task {
                                    await viewModel.flagPost(post)
                                }
                            } label: {
                                FeedCellActionButtonView(imageName: "flag",
                                                         value: post.saveCount)
                            }
                            
                            if post.user?.isCurrentUser ?? false {
                                Button {
                                    showingDeleteAlert = true
                                } label: {
                                    FeedCellActionButtonView(imageName: "trash", value: post.shareCount)
                                }
                                .alert("Are you sure you want to delete this post?", isPresented: $showingDeleteAlert) {
                                    Button("Delete", role: .destructive) {
                                        Task {
                                            await viewModel.deletePost(post)
                                            await viewModel.refreshFeed()
                                        }
                                    }
                                    Button("Cancel", role: .cancel) { }
                                } message: {
                                    Text("This action cannot be undone.")
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.bottom, viewModel.isContainedInTabBar ? 80 : 12)
                }
            }
            .fullScreenCover(isPresented: $showComments) {
                NavigationView {
                    CommentsView(post: post)
                        .navigationBarTitle("Comments", displayMode: .inline)
                        .navigationBarItems(leading: Button(action: {
                            showComments = false // This will dismiss the full-screen cover
                        }) {
                            Image(systemName: "arrow.backward") // Using a system icon for the back button
                                .foregroundStyle(.black)
                        })
                }
            }
            .onTapGesture {
                switch player.timeControlStatus {
                case .paused:
                    player.play()
                case .waitingToPlayAtSpecifiedRate:
                    break
                case .playing:
                    player.pause()
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(post) : await viewModel.like(post) }
    }
}

#Preview {
    FeedCell(
        post: .constant(DeveloperPreview.posts[0]),
        player: AVPlayer(),
             viewModel: FeedViewModel(
                feedService: FeedService(),
                postService: PostService()
             )
    )
}
