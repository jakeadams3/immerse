//
//  UserListView.swift
//  immerse
//
//

import SwiftUI

struct UserListView: View {
    @StateObject var viewModel = UserListViewModel(service: UserListService())

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(viewModel.users) { user in
                    NavigationLink(value: user) {
                        UserCell(user: user)
                            .padding(.horizontal)
                    }
                    .tint(.clear)
                }
                
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .padding(.top)
        }
    }
}

#Preview {
    UserListView()
}
