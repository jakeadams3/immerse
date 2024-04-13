//
//  FeedView.swift
//  immerse
//
//

import SwiftUI
import AVKit

struct FeedView: View {
    @StateObject var viewModel: FeedViewModel
    @State private var scrollPosition: String?
    @State private var activePostId: String?
    var showBackButton: Bool = false
    var onBackButtonTapped: (() -> Void)? // Closure to handle back button action

    init(posts: [Post] = [], showBackButton: Bool = false, onBackButtonTapped: (() -> Void)? = nil) {
        let viewModel = FeedViewModel(feedService: FeedService(),
                                      postService: PostService(),
                                      posts: posts)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.showBackButton = showBackButton
        self.onBackButtonTapped = onBackButtonTapped
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach($viewModel.posts) { post in
                            FeedCell(post: post, viewModel: viewModel, isActive: post.id == activePostId)
                                .id(post.id)
                                .onAppear {
                                    if activePostId == nil {
                                        activePostId = viewModel.posts.first?.id
                                    }
                                    if let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) {
                                        viewModel.preloadNextVideos(currentIndex: index)
                                    }
                                }
                        }
                        .onChange(of: scrollPosition) { newPosition in
                            activePostId = newPosition
                        }
                    }
                    .scrollTargetLayout()
                }

                Button {
                    Task {
                        await viewModel.refreshFeed()
                        activePostId = viewModel.posts.first?.id
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .imageScale(.large)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .padding(32)
                }
                .tint(.clear)
                .offset(z: 1)

                if showBackButton {
                    HStack {
                        Button(action: {
                            onBackButtonTapped?()
                        }) {
                            Image(systemName: "arrow.backward")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                                .padding(32)
                        }
                        .offset(z: 1)
                        Spacer()
                    }
                }
            }
            .background(.clear)
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
        }
    }
}


#Preview {
    FeedView(posts: DeveloperPreview.posts)
}
