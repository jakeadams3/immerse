//
//  FeedCell.swift
//  immerse
//
//

import SwiftUI
import AVKit

struct FeedCell: View {
    @Binding var post: Post
    @ObservedObject var viewModel: FeedViewModel
    @State private var player: AVPlayer
    @State private var expandCaption = false
    @State private var showComments = false
    @State private var showingDeleteAlert = false
    @State private var showingFlagAlert = false
    let isActive: Bool
    
    private var didLike: Bool { return post.didLike }
    
    init(post: Binding<Post>, viewModel: FeedViewModel, isActive: Bool) {
        self._post = post
        self.viewModel = viewModel
        self.isActive = isActive
        
        if let preloadedPlayer = viewModel.preloadedPlayers[post.wrappedValue.id] {
            self._player = State(initialValue: preloadedPlayer)
        } else {
            self._player = State(initialValue: AVPlayer())
        }
    }
    
    var body: some View {
        ZStack {
            if post.isOwnerBlocked {
                Color.black.opacity(0.7)
                    .overlay(Text("This post is from a blocked user.")
                        .foregroundColor(.white))
                    .containerRelativeFrame([.horizontal, .vertical])
            } else {
                SpatialVideoPlayerRepresentable(player: player, videoURL: post.videoUrl)
                    .onAppear {
                        if player.currentItem == nil {
                            let playerItem = AVPlayerItem(url: URL(string: post.videoUrl)!)
                            player.replaceCurrentItem(with: playerItem)
                        }
                        
                        // Add observer for AVPlayerItemDidPlayToEndTime notification
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [self] _ in
                            self.player.seek(to: CMTime.zero)
                            self.player.play()
                        }
                        
                        if isActive {
                            player.play()
                        }
                    }
                    .onChange(of: isActive) { shouldPlay in
                        if shouldPlay {
                            player.play()
                        } else {
                            player.pause()
                        }
                    }
                    .onDisappear {
                        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                        player.pause()
                        player.replaceCurrentItem(with: nil)
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
            }
            
            ZStack {
                VStack {
                    Spacer()
                    
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, .black.opacity(0.05)],
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
                            
                                .ornament(
                                    visibility: isActive ? .visible : .hidden,
                                    attachmentAnchor: .scene(.trailing)
                                ) {
                                    VStack(spacing: 28) {
                                        NavigationLink(value: post.user) {
                                            ZStack(alignment: .bottom) {
                                                CircularProfileImageView(user: post.user, size: .xLarge)
                                            }
                                        }
                                        .padding(.bottom, 20)
                                        
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
                                    .padding(.vertical)
                                    .glassBackgroundEffect()
                                }
                        }
                        .padding(.bottom, viewModel.isContainedInTabBar ? 80 : 12)
                    }
                }
                .offset(z: 1)
                .fullScreenCover(isPresented: $showComments) {
                    NavigationView {
                        CommentsView(post: post)
                            .navigationBarTitle("Comments", displayMode: .inline)
                            .navigationBarItems(leading: Button(action: {
                                showComments = false // This will dismiss the full-screen cover
                            }) {
                                Image(systemName: "arrow.backward") // Using a system icon for the back button
                                    .imageScale(.large)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                            })
                            .tint(.clear)
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
    }
    
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(post) : await viewModel.like(post) }
    }
}


#Preview {
    FeedCell(
        post: .constant(DeveloperPreview.posts[0]),
        viewModel: FeedViewModel(
            feedService: FeedService(),
            postService: PostService(),
            posts: DeveloperPreview.posts
        ),
        isActive: true
    )
}
