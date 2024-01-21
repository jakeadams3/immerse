//
//  ExploreView.swift
//  immerse
//
//

import SwiftUI

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            UserListView()
                .navigationTitle("Explore")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: User.self) { user in
                    ProfileView(user: user)
                }
        }
    }
}

#Preview {
    ExploreView()
}
