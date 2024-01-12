//
//  VideoPlayer.swift
//  TikTokClone
//
//  Created by Stephan Dowless on 10/8/23.
//

import SwiftUI
import AVFoundation
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    var player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        // Create an AVPlayerLayer and set it as the view's layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)

        return view // last integration check
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the layer's frame to match the new view size
        if let layer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            layer.frame = uiView.bounds
        }
    }
}
