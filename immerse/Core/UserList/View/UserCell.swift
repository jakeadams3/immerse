//
//  UserCell.swift
//  immerse
//
//

import SwiftUI

struct UserCell: View {
    let user: User
    
    init(user: User) {
        self.user = user
    }
    
    var body: some View {
        HStack(spacing: 16) {
            CircularProfileImageView(user: user, size: .xLarge)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(user.fullname)
                    .fontWeight(.semibold)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            //            Button {
            //
            //            } label: {
            //                Text("Follow")
            //                    .font(.system(size: 14, weight: .semibold))
            //                    .frame(width: 88, height: 32)
            //                    .foregroundColor(.white)
            //                    .background(.pink)
            //                    .cornerRadius(6)
            //            }
        }
        .padding(.horizontal)
        .padding(.vertical, 15)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(80)
        .overlay(
            RoundedRectangle(cornerRadius: 80)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(radius: 5)
    }
}

#Preview {
    UserCell(user: DeveloperPreview.user)
}
