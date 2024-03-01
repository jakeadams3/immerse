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
    
    init(posts: [Post] = []) {
        let viewModel = FeedViewModel(feedService: FeedService(),
                                      postService: PostService(),
                                      posts: posts)
        self._viewModel = StateObject(wrappedValue: viewModel)
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
