//
//  FeedCellActionButtonView.swift
//  immerse
//
//

import SwiftUI

struct FeedCellActionButtonView: View {
    let imageName: String
    let value: Int
    var height: CGFloat? = 28
    var width: CGFloat? = 28
    var tintColor: Color?
    
    var body: some View {
        VStack {
            Image(systemName: imageName)
                .resizable()
                .frame(width: width, height: height)
                .foregroundStyle(tintColor ?? .white)
            
            if value > 0 {
                Text("\(value)")
                    .font(.body)
                    .fontWeight(.bold)
            }
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    FeedCellActionButtonView(imageName: "heart.fill", value: 40)
}
