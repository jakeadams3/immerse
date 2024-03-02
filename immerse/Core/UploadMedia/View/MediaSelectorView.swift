//
//  MediaSelectorView.swift
//  immerse
//
//

import SwiftUI
import AVKit

struct MediaSelectorView: View {
    @State private var player = AVPlayer()
    @StateObject var viewModel = UploadPostViewModel(service: UploadPostService())
    @State private var showImagePicker = false
    @Binding var tabIndex: Int
    
    var body: some View {
        NavigationStack {
            VStack {
                if let movie = viewModel.mediaPreview {
                    SpatialVideoPlayerRepresentable(player: player, videoURL: movie.url.absoluteString)
                        .scaleEffect(0.9)
                        .onAppear {
                            let playerItem = AVPlayerItem(url: movie.url)
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
                                self.player.seek(to: CMTime.zero)
                                self.player.play()
                            }
                            player.replaceCurrentItem(with: playerItem)
                            player.play()
                        }
                        .onDisappear {
                            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                            player.pause()
                            player.replaceCurrentItem(with: nil)
                        }
                        .onTapGesture {
                            if player.timeControlStatus == .playing {
                                player.pause()
                            } else {
                                player.play()
                            }
                        }
                        .padding()
                }
            }
            .onAppear {
                if viewModel.selectedMediaForUpload == nil { showImagePicker.toggle() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        player.pause()
                        player = AVPlayer(playerItem: nil)
                        viewModel.reset()
                        tabIndex = 0
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                    }
                    .foregroundStyle(.black)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next") {
                        viewModel.setMediaItemForUpload()
                    }
                    .disabled(viewModel.mediaPreview == nil)
                    .font(.headline)
                    .foregroundStyle(.black)
                }
            }
            .navigationDestination(item: $viewModel.selectedMediaForUpload, destination: { movie in
                UploadPostView(movie: movie, viewModel: viewModel, tabIndex: $tabIndex)
            })
            .photosPicker(isPresented: $showImagePicker, selection: $viewModel.selectedItem, matching: .videos)
            .toolbar(.hidden, for: .tabBar)
        }
    }
}

#Preview {
    MediaSelectorView(tabIndex: .constant(0))
}
