//
//  SpatialVideoPlayer.swift
//  immerse
//
//  Created by Jake Adams on 2/23/24.
//

import SwiftUI
import AVKit
import RealityKit
import UIKit

struct SpatialVideoPlayerRepresentable: UIViewControllerRepresentable {
    var player: AVPlayer
    let videoURL: String

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = UIViewController()
        viewController.showSpatialVideoPlayer(player: player, videoURL: videoURL)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Update the view controller if needed.
    }
}

// MARK: - SwiftUI View for displaying video content in RealityKit
struct SpatialVideoPlayer: View {
    @Binding var player: AVPlayer
    let videoURL: String
    
    init(player: Binding<AVPlayer>, videoURL: String) {
        self._player = player
        self.videoURL = videoURL
    }
    
    var body: some View {
        RealityView { content in
            guard let url = URL(string: videoURL) else {
                return
            }
            
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            let videoPlayerComponent = VideoPlayerComponent(avPlayer: player)
            let videoEntity = Entity()
            videoEntity.components[VideoPlayerComponent.self] = videoPlayerComponent
            videoEntity.position = SIMD3<Float>(0, 0, 0.0001)
            videoEntity.scale = SIMD3<Float>(0.99, 0.99, 1)
            content.add(videoEntity)
        }
        .scaledToFit()
    }
}

// MARK: - UIKit Integration using UIHostingController
extension UIViewController {
    func showSpatialVideoPlayer(player: AVPlayer, videoURL: String) {
        let spatialVideoPlayerView = SpatialVideoPlayer(player: Binding.constant(player), videoURL: videoURL)
        let hostingController = UIHostingController(rootView: spatialVideoPlayerView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Auto Layout constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
