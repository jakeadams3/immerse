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
                    
                    PostGridView(viewModel: profileViewModel)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        authService.signout()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                }
            }
            .task { await profileViewModel.fetchUserPosts() }
            .task { await profileViewModel.fetchUserStats() }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CurrentUserProfileView(authService: AuthService(),
                           user: DeveloperPreview.user)
}
