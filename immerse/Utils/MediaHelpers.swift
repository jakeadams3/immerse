//
//  MediaHelpers.swift
//  immerse
//
//

import SwiftUI
import AVKit

struct MediaHelpers {
    static func generateThumbnail(path: String) async -> UIImage? {
        do {
            guard let url = URL(string: path) else { return nil }
            let asset = AVURLAsset(url: url, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true

            // Use the new async method
            let (cgImage, _) = try await imgGenerator.image(at: CMTimeMake(value: 0, timescale: 1))
            return UIImage(cgImage: cgImage)
        } catch {
            print("DEBUG: Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}
