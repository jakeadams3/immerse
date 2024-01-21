//
//  VideoPlayerViewModel.swift
//  immerse
//
//

import AVKit

class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer

    init(url: String) {
        self.player = AVPlayer(url: URL(string: url)!)
    }
}
