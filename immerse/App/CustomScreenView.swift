//
//  EnvironmentRV.swift
//  immerse
//
//

import SwiftUI
import AVFoundation
import AVKit
import RealityKit

struct CustomScreenView: View {
    var body: some View {
        RealityView() { content in
            // Use the URL of the video from the web
            let url = URL(string: "https://pub-f0b404514b5d424e9a73685eb0b9f638.r2.dev/spatial1.MOV")!

            // Create a simple AVPlayer
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let player = AVPlayer(playerItem: playerItem)

            // Create a videoMaterial
            let videoMaterial = VideoMaterial(avPlayer: player)

            // Load the USDZ file
            guard let curvedScreenEntity = try? Entity.load(named: "flatPlane") else {
                print("Error: USDZ file not loaded.")
                return
            }

            // Function to apply video material to all model entities
            @MainActor func applyVideoMaterial(to entity: Entity) {
                if let modelEntity = entity as? ModelEntity {
                    modelEntity.model?.materials = [videoMaterial]
                }

                // Apply to child entities
                for child in entity.children {
                    applyVideoMaterial(to: child)
                }
            }

            // Apply video material to the curved screen entity and its children
            applyVideoMaterial(to: curvedScreenEntity)

            // Adjust the properties of the entity (size, angle, etc.)
            curvedScreenEntity.scale = .init(x: 1, y: 1, z: 1)
            
            // Add the curved screen entity to RealityView
            content.add(curvedScreenEntity)
            
            // Start the VideoPlayer
            player.play()
        }
    }
}

#Preview {
    CustomScreenView()
}
