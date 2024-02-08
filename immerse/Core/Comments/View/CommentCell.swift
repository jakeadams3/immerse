//
//  CommentCell.swift
//  immerse
//
//

import SwiftUI

import SwiftUI

struct CommentCell: View {
    let comment: Comment
    
    var body: some View {
        HStack {
            CircularProfileImageView(user: comment.user, size: .large)
                .padding(.trailing)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text(comment.user?.username ?? "")
                        .foregroundStyle(.white)
                        .font(.title2)
                    
                    Text(" \(comment.timestamp.timestampString())")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.body)
                }
                
                Text(comment.commentText)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .font(.title2)
            }
            
            Spacer()
        }
        .padding(.vertical, 15)
    }
}

#Preview {
    CommentCell(comment: DeveloperPreview.comment)
}
