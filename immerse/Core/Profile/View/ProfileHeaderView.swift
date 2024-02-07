//
//  ProfileHeaderView.swift
//  immerse
//
//

import SwiftUI

struct ProfileHeaderView: View {
    @State private var showEditProfile = false
    @ObservedObject var viewModel: ProfileViewModel
    
    private var user: User {
        return viewModel.user
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                CircularProfileImageView(user: user, size: .huge)
                
                Text("@\(user.username)")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }
            
            // stats view
            HStack(spacing: 16) {
                UserStatView(value: user.stats.following, title: "Following")
                
                UserStatView(value: user.stats.followers, title: "Followers")
                
                UserStatView(value: user.stats.likes, title: "Likes")
            }
            
            // action button view
            if user.isCurrentUser {
                Button {
                    showEditProfile.toggle()
                } label: {
                    Text("Edit Profile")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(width: 400, height: 50)
                        .foregroundStyle(.black)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                }
            } else {
                Button {
                    handleFollowTapped()
                } label: {
                    Text(user.isFollowed ? "Following" : "Follow")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(width: 400, height: 50)
                        .foregroundStyle(user.isFollowed ? .black : .white)
                        .background(user.isFollowed ? .white : .black)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                }
                .tint(.clear)
            }
            
            // bio
            if let bio = user.bio {
                Text(bio)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Divider()
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView(user: $viewModel.user)
        }
    }
    
    func handleFollowTapped() {
        user.isFollowed ? viewModel.unfollow() : viewModel.follow()
    }
}

struct UserStatView: View {
    let value: Int
    let title: String
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .opacity(value == 0 ? 0.5 : 1.0)
        .frame(width: 80, alignment: .center)
    }
}

#Preview {
    ProfileHeaderView(viewModel: ProfileViewModel(
        user: DeveloperPreview.user,
        userService: UserService(),
        postService: PostService())
    )
}
