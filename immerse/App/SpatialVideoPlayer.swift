//
//  SpatialVideoPlayer.swift
//  immerse
//
//  Created by Jake Adams on 2/23/24.
//

import SwiftUI
import AVKit
import RealityKit

struct SpatialVideoPlayer: View {
    @Binding var player: AVPlayer
    let videoURL: String
    
    init(player: Binding<AVPlayer>, videoURL: String) {
        self._player = player
        self.videoURL = videoURL
    }
    
    var body: some View {
        RealityView { content in
            // Ensure the URL is valid
            guard let url = URL(string: videoURL) else {
                return
            }
            
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            // Use the provided AVPlayer instance
            // Create a VideoPlayerComponent object supplying the AVPlayer object
            let videoPlayerComponent = VideoPlayerComponent(avPlayer: player)
            
            // Create an entity for display and add the VideoPlayerComponent to it
            let videoEntity = Entity()
            videoEntity.components[VideoPlayerComponent.self] = videoPlayerComponent
            
            // Scale the entity to 50% of its original size
//            videoEntity.scale = SIMD3<Float>(0.5, 0.5, 0.5)
            
            videoEntity.position = SIMD3<Float>(0, 0, 0.0001)
            
            // Add the entity to the RealityView's content
            content.add(videoEntity)

        }
    }
}
