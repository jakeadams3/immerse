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
                    
                    // Optionally, place the Delete Account button here instead of in the toolbar
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete Account") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        authService.signout()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(title: Text("Delete Account"),
                      message: Text("Are you sure you want to permanently delete your account? This cannot be undone."),
                      primaryButton: .destructive(Text("Delete"), action: deleteAccount),
                      secondaryButton: .cancel()
                )
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await profileViewModel.fetchUserPosts() }
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
