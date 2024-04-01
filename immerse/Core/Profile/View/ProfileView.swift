//
//  ProfileView.swift
//  immerse
//
//

import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingBlockAlert = false
    @State private var attemptingToBlock = false
    
    private var user: User {
        return viewModel.user
    }
    
    init(user: User) {
        let profileViewModel = ProfileViewModel(user: user, 
                                                userService: UserService(),
                                                postService: PostService())
        self._viewModel = StateObject(wrappedValue: profileViewModel)
        
        UINavigationBar.appearance().tintColor = .primaryText
    }
    
    var body: some View {
        ScrollView {
                    VStack(spacing: 2) {
                        ProfileHeaderView(viewModel: viewModel)
                            .tint(.clear)
                        
                        if viewModel.isBlocked {
                            // Display blurred view with overlay text for blocked user
                            Rectangle()
                                .foregroundStyle(.clear)
                                .frame(height: 150)
                                .overlay(
                                    Text("This user is currently blocked.")
                                        .font(.title)
                                        .foregroundColor(.black)
                                )
                                .padding([.top, .leading, .trailing])
                        } else {
                            VStack {
                                // Display PostGridView normally for non-blocked user
                                PostGridView(viewModel: viewModel)
                                    .tint(.clear)
                                Spacer(minLength: 1350) // Add a Spacer at the bottom
                            }
                        }
                    }
                }
        .task { await viewModel.fetchUserPosts() }
        .task { await viewModel.checkIfUserIsFollowed() }
        .task { await viewModel.fetchUserStats() }
        .navigationTitle(user.username)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.backward")
                        .foregroundStyle(.black)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !user.isCurrentUser {
                    Button(action: {
                        if viewModel.isBlocked {
                            Task {
                                await viewModel.unblockUser()
                            }
                        } else {
                            attemptingToBlock = true
                            showingBlockAlert = true
                        }
                    }) {
                        Image(systemName: viewModel.isBlocked ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.badge.xmark")
                            .font(.title3)
                            .foregroundColor(viewModel.isBlocked ? .blue : .red)
                    }
                    .onAppear {
                        Task {
                            await viewModel.checkBlocked()
                        }
                    }
                }
            }
        }
        .alert("Are you sure you want to block this user?", isPresented: $showingBlockAlert) {
            Button("Block", role: .destructive) {
                Task {
                    await viewModel.blockUser()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        message: {
            Text("You'll no longer be able to view content from this account.")
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    ProfileView(user: DeveloperPreview.user)
}
