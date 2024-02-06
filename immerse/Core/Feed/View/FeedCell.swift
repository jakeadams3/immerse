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
    @State private var showingFlagAlert = false
        
    private var didLike: Bool { return post.didLike }
    
    var body: some View {
        ZStack {
            if post.isOwnerBlocked {
                // Display a placeholder or nothing if the post is from a blocked user
                Color.black.opacity(0.7)
                    .overlay(Text("This post is from a blocked user.")
                        .foregroundColor(.white))
                    .containerRelativeFrame([.horizontal, .vertical])
            } else {
                // Only create and show the VideoPlayer if the user is not blocked
                VideoPlayerView(player: player)
                    .containerRelativeFrame([.horizontal, .vertical])

            }
                    
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
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text(post.caption)
                                .lineLimit(expandCaption ? 50 : 2)
                            
                        }
                        .onTapGesture { withAnimation(.snappy) { expandCaption.toggle() } }
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding()
                        
                        Spacer()
                        
                        VStack(spacing: 28) {
                            NavigationLink(value: post.user) {
                                ZStack(alignment: .bottom) {
                                    CircularProfileImageView(user: post.user, size: .xLarge)
                                }
                            }
                            
                            Button {
                                handleLikeTapped()
                            } label: {
                                FeedCellActionButtonView(imageName: didLike ? "heart.fill" : "heart",
                                                         value: post.likes,
                                                         height: 40,
                                                         width: 40,
                                                         tintColor: didLike ? .red : .white)
                            }
                            
                            Button {
                                player.pause()
                                showComments.toggle()
                            } label: {
                                FeedCellActionButtonView(imageName: "ellipsis.bubble", 
                                                         value: post.commentCount,
                                                         height: 40,
                                                         width: 40)
                            }
                            
                            Button {
                                if post.didFlag {
                                    Task {
                                        await viewModel.toggleFlagForPost(post)
                                    }
                                } else {
                                    showingFlagAlert = true
                                }
                            } label: {
                                FeedCellActionButtonView(imageName: post.didFlag ? "flag.fill" : "flag",
                                                         value: post.saveCount,
                                                         height: 38,
                                                         width: 38)
                            }
                            .alert(isPresented: $showingFlagAlert) {
                                Alert(
                                    title: Text("Are you sure you want to report this post?"),
                                    primaryButton: .destructive(Text("Report")) {
                                        Task {
                                            await viewModel.toggleFlagForPost(post)
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                            
                            if post.user?.isCurrentUser ?? false {
                                Button {
                                    showingDeleteAlert = true
                                } label: {
                                    FeedCellActionButtonView(imageName: "trash", 
                                                             value: post.shareCount,
                                                             height: 40,
                                                             width: 40)
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
                        .tint(.clear)
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
        .blur(radius: post.isOwnerBlocked ? 20 : 0)
        .disabled(post.isOwnerBlocked) // Disable interaction if the post's owner is blocked
                .overlay(
                    Group {
                        if post.isOwnerBlocked {
                            Text("This post is from a blocked user.")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .font(.title)
                        } else {
                            EmptyView()
                        }
                    }
                )
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
