//
//  EditProfileView.swift
//  immerse
//
//

import SwiftUI
import PhotosUI

enum EditProfileOptions: Hashable {
    case fullname
    case username
    case bio
    
    var navigationTitle: String {
        switch self {
        case .fullname: return "Name"
        case .username: return "Username"
        case .bio: return "Bio"
        }
    }
}


struct EditProfileView: View {
    @StateObject var viewModel = EditProfileViewModel()
    @State private var profileImage: Image?
    @State private var uiImage: UIImage?
    @State private var selectedPickerItem: PhotosPickerItem?
    @State private var fullname: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @Environment(\.dismiss) var dismiss
    @Binding var user: User
    
    init(user: Binding<User>) {
        self._user = user
        self._fullname = State(initialValue: user.fullname.wrappedValue)
        self._username = State(initialValue: user.username.wrappedValue)
        self._bio = State(initialValue: user.bio.wrappedValue ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PhotosPicker(selection: $selectedPickerItem, matching: .images) {
                    VStack(spacing: 16) {
                        if let image = profileImage {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: ProfileImageSize.xLarge.dimension, height: ProfileImageSize.xLarge.dimension)
                                .clipShape(Circle())
                        } else {
                            CircularProfileImageView(user: user, size: .xLarge)
                        }
                        
                        Text("Change photo")
                            .font(.subheadline)
                            .foregroundStyle(.black)
                            .fontWeight(.semibold)
                    }
                    .padding()
                }

                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("About you")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .fontWeight(.semibold)
                            .padding(.bottom, 8)

                        HStack {
                            Text("Name")
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            TextField("Enter your name", text: $fullname)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.bottom, 4)
                        
                        HStack {
                            Text("Username")
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            TextField("Choose a username", text: $username)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.bottom, 4)
                        
                        HStack {
                            Text("Bio")
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            TextField("Write something about you", text: $bio)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
                .padding()
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            do {
                                try await viewModel.updateUserProfile(fullname: fullname, username: username, bio: bio)
                                if let uiImage = uiImage {
                                    let imageUrl = await viewModel.uploadProfileImage(uiImage)
                                    user.profileImageUrl = imageUrl
                                }
                                user.fullname = fullname
                                user.username = username
                                user.bio = bio
                                dismiss()
                            } catch {
                                print("Error updating profile: \(error)")
                            }
                        }
                    }
                    .foregroundStyle(.black)
                }
            }
            .onChange(of: selectedPickerItem) { newValue in
                Task { await loadImage(fromItem: newValue) }
            }
        }
    }
}

extension EditProfileView {
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.profileImage = Image(uiImage: uiImage)
    }
    
    func updateProfileImage() {
        Task {
            guard let uiImage = uiImage else { return }
            let imageUrl = await viewModel.uploadProfileImage(uiImage)
            user.profileImageUrl = imageUrl
        }
    }
}

#Preview {
    EditProfileView(user: .constant(DeveloperPreview.user))
}
