//
//  ImageUploader.swift
//  immerse
//
//

import UIKit
import Firebase
import FirebaseStorage

enum UploadType {
    case profile
    case post
    
    var filePath: StorageReference {
        let filename = NSUUID().uuidString
        switch self {
        case .profile:
            return Storage.storage().reference(withPath: "/profile_images/\(filename)")
        case .post:
            return Storage.storage().reference(withPath: "/post_images/\(filename)")
        }
    }
}

struct ImageUploader {
    static func uploadImage(image: UIImage, type: UploadType) async throws -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
        let ref = type.filePath
        
        do {
            let _ = try await ref.putDataAsync(imageData)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            print("DEBUG: Failed to upload image \(error.localizedDescription)")
            return nil
        }
    }
}

import UIKit
import Firebase
import FirebaseStorage
import AVFoundation

struct VideoUploader {
    static func uploadVideoToStorage(withUrl originalUrl: URL) async throws -> String? {
        // Trims the video to the first 180 seconds
        guard let trimmedVideoUrl = await trimVideo(url: originalUrl, duration: 180) else {
            print("DEBUG: Failed to trim video")
            return nil
        }
        
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference(withPath: "/post_videos/").child(filename)
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        
        do {
            let data = try Data(contentsOf: trimmedVideoUrl)
            let _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            print("DEBUG: Failed to upload video with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func trimVideo(url: URL, duration: Int) async -> URL? {
        let asset = AVAsset(url: url)
        let length = CMTimeGetSeconds(asset.duration)
        let startTime = CMTime(seconds: 0, preferredTimescale: 600)
        let endTime = CMTime(seconds: min(Double(duration), length), preferredTimescale: 600)
        
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        
        return await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: outputURL)
                default:
                    print("DEBUG: Video trimming failed with error: \(String(describing: exportSession.error?.localizedDescription))")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
