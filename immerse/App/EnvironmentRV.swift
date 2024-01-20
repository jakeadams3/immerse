//
//  EnvironmentRV.swift
//  immerse
//
//  Created by Jake Adams on 1/15/24.
//

import SwiftUI
import AVFoundation
import AVKit
import RealityKit

struct EnvironmentRV: View {
    var body: some View {
        RealityView() { content in
            // Use the URL of the video from the web
            let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4")!

            // Create a simple AVPlayer
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let player = AVPlayer(playerItem: playerItem)

            // Create a videoMaterial
            let videoMaterial = VideoMaterial(avPlayer: player)

            // Load the USDZ file
            guard let curvedScreenEntity = try? Entity.load(named: "CurvedScreen") else {
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
    EnvironmentRV()
}
