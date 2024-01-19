//
//  EnvironmentRV.swift
//  immerse
//
//  Created by Jake Adams on 1/15/24.
//

import SwiftUI
import RealityKit

struct EnvironmentRV: View {
    var body: some View {
        RealityView() { content in
            
            // Load texture from xcassets
            guard let texture = try? TextureResource.load(named: "beach") else {
                print("Error: Texture not loaded.")
                return
            }

            // Load the USDZ file
            guard let curvedScreenEntity = try? Entity.load(named: "CurvedScreen") else {
                print("Error: USDZ file not loaded.")
                return
            }

            // Function to apply material to all model entities
            @MainActor func applyMaterial(to entity: Entity) {
                if let modelEntity = entity as? ModelEntity {
                    var material = UnlitMaterial()
                    material.color = .init(texture: .init(texture))
                    modelEntity.model?.materials = [material]
                }

                // Apply to child entities
                for child in entity.children {
                    applyMaterial(to: child)
                }
            }

            // Apply material to the curved screen entity and its children
            applyMaterial(to: curvedScreenEntity)

            // Adjust the properties of the entity (size, angle, etc.)
            curvedScreenEntity.scale = .init(x: 1, y: 1, z: 1)
            
            // Add the curved screen entity to RealityView
            content.add(curvedScreenEntity)
            
        } update: { content in
            // Update the RealityKit content
        }
    }
}

#Preview {
    EnvironmentRV()
}
