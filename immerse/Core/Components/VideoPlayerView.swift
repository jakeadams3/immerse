//
//  VideoPlayer.swift
//  immerse
//
//

import SwiftUI
import AVKit

// Define a UIView subclass to host the AVPlayerLayer
class PlayerView: UIView {
    private var playerLayer = AVPlayerLayer()

    // Initialize with an AVPlayer
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect // Adjust as needed
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// UIViewRepresentable wrapper for the PlayerView
struct VideoPlayerView: UIViewRepresentable {
    var player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        return PlayerView(player: player)
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        // No need to update anything for now; the PlayerView handles resizing
    }
}
