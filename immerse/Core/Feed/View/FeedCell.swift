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
                                
                                Text(formattedTimestamp)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text(post.caption)
                                    .lineLimit(expandCaption ? 50 : 2)
                                                                
                            }
                            .onTapGesture { withAnimation(.snappy) { expandCaption.toggle() } }
                            .font(.body)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.7), radius: 4)
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
                            // ADD THE STARS ORNAMENT HERE
                                .ornament(
                                    visibility: isActive ? .visible : .hidden,
                                    attachmentAnchor: .scene(.bottom)
                                ) {
                                    VStack {
                                        Text("\(post.ratings) ratings")
                                            .padding(.top)
                                        
                                        // Add the rating bar
                                        HStack {
                                            ZStack(alignment: .leading) {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(height: 8)
                                                
                                                Rectangle()
                                                    .fill(Color.yellow)
                                                    .frame(width: calculateBarWidth(post.averageRating), height: 8)
                                                    .animation(.linear(duration: 0.3), value: calculateBarWidth(post.averageRating))
                                                
                                            }
                                            .cornerRadius(4)
                                            .padding(.horizontal)
                                            
                                            Text(formatAverageRating(post.averageRating))
                                                .font(.title2)
                                                .padding(.trailing)
                                        }
                                        
                                        HStack {
                                            ForEach(1...5, id: \.self) { rating in
                                                Button {
                                                    handleStarTapped(rating)
                                                } label: {
                                                    Image(systemName: post.userRating >= rating ? "star.fill" : "star")
                                                        .resizable()
                                                        .frame(width: 40, height: 40)
                                                        .foregroundStyle(post.userRating >= rating ? .yellow : .white)
                                                        .shadow(radius: 2)
                                                        .padding(.bottom)
                                                }
                                            }
                                            
                                        }
                                        .padding(.horizontal)
                                    }
                                    .tint(.clear)
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
    
    private func handleStarTapped(_ rating: Int) {
        Task {
            if post.userRating == rating {
                post.userRating = 0
                post.ratings -= 1
                post.averageRating = calculateUpdatedAverageRating(removing: rating)
                await viewModel.removePostRating(post)
            } else {
                if post.userRating != 0 {
                    post.ratings -= 1
                    post.averageRating = calculateUpdatedAverageRating(removing: post.userRating)
                }
                post.userRating = rating
                post.ratings += 1
                post.averageRating = calculateUpdatedAverageRating(adding: rating)
                await viewModel.ratePost(post, rating: rating)
            }
        }
    }

    private func calculateUpdatedAverageRating(adding rating: Int) -> String {
        let components = post.averageRating.components(separatedBy: "/")
        guard var numerator = Double(components[0]), var denominator = Double(components[1]) else {
            return "\(rating)/1"
        }
        if numerator == 0 && denominator == 1 {
            return "\(rating)/1"
        } else {
            numerator += Double(rating)
            denominator += 1
            return "\(Int(numerator))/\(Int(denominator))"
        }
    }

    private func calculateUpdatedAverageRating(removing rating: Int) -> String {
        let components = post.averageRating.components(separatedBy: "/")
        guard var numerator = Double(components[0]), var denominator = Double(components[1]) else {
            return "0/0"
        }
        numerator -= Double(rating)
        denominator -= 1
        return "\(Int(numerator))/\(Int(denominator))"
    }
    
    func formatAverageRating(_ averageRating: String) -> String {
        let components = averageRating.components(separatedBy: "/")
        guard let numerator = Double(components[0]), let denominator = Double(components[1]), denominator != 0 else {
            return "0.00"
        }
        let formattedRating = String(format: "%.2f", numerator / denominator)
        return formattedRating
    }
    
    func calculateBarWidth(_ averageRating: String) -> CGFloat {
        let components = averageRating.components(separatedBy: "/")
        guard let numerator = Double(components[0]), let denominator = Double(components[1]), denominator != 0 else {
            return 0
        }
        let percentage = numerator / denominator / 5
        return percentage * 360 // Adjust the multiplier as needed to set the maximum width of the bar
    }
    
    private var formattedTimestamp: String {
        let timestamp = post.timestamp
        
        let currentDate = Date()
        let postDate = timestamp.dateValue()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.day, .hour, .minute], from: postDate, to: currentDate)
        
        if let days = components.day, days >= 7 {
            let dateFormatter = DateFormatter()
            
            let postYear = calendar.component(.year, from: postDate)
            let currentYear = calendar.component(.year, from: currentDate)
            
            if postYear == currentYear {
                dateFormatter.dateFormat = "M/d"
                return "on \(dateFormatter.string(from: postDate))"
            } else {
                dateFormatter.dateFormat = "M/d/yy"
                return "on \(dateFormatter.string(from: postDate))"
            }
            
            return dateFormatter.string(from: postDate)
        } else if let days = components.day, days >= 1 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours >= 1 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes >= 1 {
            return "\(minutes)min ago"
        } else {
            return "Just Now"
        }
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
