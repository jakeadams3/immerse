//
//  CommentInputView.swift
//  immerse
//
//

import SwiftUI

import SwiftUI

struct CommentInputView: View {
    @ObservedObject var viewModel: CommentViewModel
    @FocusState private var fieldIsActive: Bool
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
            TextField("Add a comment", text: $viewModel.commentText)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .focused($fieldIsActive)
            
            Button {
                Task {
                    await viewModel.uploadComment()
                    fieldIsActive = false
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
        }
        }
        .tint(.clear)
    }
}
