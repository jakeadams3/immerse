//
//  CurrentUserProfileView.swift
//  immerse
//
//

import SwiftUI

struct CurrentUserProfileView: View {
    let authService: AuthService
    let user: User
    @StateObject var profileViewModel: ProfileViewModel
    @State private var showingDeleteAlert = false
    @State private var selectedTab = 0
    
    init(authService: AuthService, user: User) {
        self.authService = authService
        self.user = user
        let viewModel = ProfileViewModel(user: user,
                                         userService: UserService(),
                                         postService: PostService())
        self._profileViewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 2) {
                    ProfileHeaderView(viewModel: profileViewModel)
                        .padding(.top)
                    
                    HStack(spacing: 20) {
                        Button("Posts") {
                            selectedTab = 0
                        }
                        .background(selectedTab == 0 ? Color.white : Color.clear)
                        .cornerRadius(40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .font(.title3)
                        .foregroundColor(selectedTab == 0 ? .black : .gray)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        
                        Button("Likes") {
                            selectedTab = 1
                        }
                        .background(selectedTab == 1 ? Color.white : Color.clear)
                        .cornerRadius(40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .font(.title3)
                        .foregroundColor(selectedTab == 1 ? .black : .gray)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 15)
                    
                    Divider()
                    
                    VStack {
                        if selectedTab == 0 {
                            PostGridView(viewModel: profileViewModel)
                        } else {
                            LikedPostsGridView(viewModel: profileViewModel)
                        }
                        
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete Account") {
                        showingDeleteAlert = true
                    }
                    .cornerRadius(40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.red, lineWidth: 2)
                    )
                    .font(.title3)
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        authService.signout()
                    }
                    .cornerRadius(40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.trailing)
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(title: Text("Delete Account"),
                      message: Text("Are you sure you want to permanently delete your account? This cannot be undone."),
                      primaryButton: .destructive(Text("Delete"), action: deleteAccount),
                      secondaryButton: .cancel()
                )
            }
            .tint(.clear)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await profileViewModel.fetchUserPosts() }
        .task { await profileViewModel.fetchLikedPosts() } // Add this line
        .task { await profileViewModel.fetchUserStats() }
    }
    
    private func deleteAccount() {
        Task {
            do {
                try await authService.deleteAccount()
                // Perform any additional cleanup if needed, e.g., navigate to the login screen
            } catch {
                print("Error deleting account: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    CurrentUserProfileView(authService: AuthService(),
                           user: DeveloperPreview.user)
}
