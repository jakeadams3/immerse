//
//  UploadPostView.swift
//  immerse
//
//

import SwiftUI

struct UploadPostView: View {
    let movie: Movie
    @ObservedObject var viewModel: UploadPostViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var tabIndex: Int
    
    var body: some View {
        GeometryReader { geometry in
            let width = (geometry.size.width / 1.5) - 2
            let height = (width * 9) / 16
            VStack {
                TextField("Enter your caption..", text: $viewModel.caption)
                    .textFieldStyle(.roundedBorder)
                    .font(.title)
                    .fontWeight(.semibold)
                    .tint(.white)
                
                Spacer()
                
                Text("Thumbnail:")
                    .font(.largeTitle)
                
                if let uiImage = viewModel.thumbnailImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Spacer()
                
                Button {
                    Task {
                        await viewModel.uploadPost()
                        if viewModel.error == nil {
                            tabIndex = 0
                            viewModel.reset()
                            dismiss()
                        }
                    }
                } label: {
                    Text(viewModel.isLoading ? "" : "Post")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(width: 500, height: 62)
                        .foregroundStyle(.black)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .overlay {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.black)
                            }
                        }
                }
                .disabled(viewModel.isLoading)
                .alert("Error Uploading", isPresented: $viewModel.showErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(viewModel.error?.localizedDescription ?? "An unexpected error occurred")
                }
                
                Spacer()
            }
            .tint(.clear)
            .padding()
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .foregroundStyle(.black)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadThumbnail(for: movie)
                }
            }
        }
    }
}

#Preview {
    UploadPostView(movie: Movie(url: URL(string: "")!),
                   viewModel: UploadPostViewModel(service: UploadPostService()),
                   tabIndex: .constant(0))
}
