//
//  VideoPlayerViewModel.swift
//  immerse
//
//  Created by Jake Adams on 12/1/23.
//

import AVKit

class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer

    init(url: String) {
        self.player = AVPlayer(url: URL(string: url)!)
    }
}
