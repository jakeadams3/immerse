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
import AVFoundation
import SotoS3

struct VideoUploader {
    static let s3Client: S3 = {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let accessKeyId = config["AccessKeyId"] as? String,
              let secretAccessKey = config["SecretAccessKey"] as? String else {
            fatalError("Failed to load API keys from Config.plist")
        }

        let client = AWSClient(
            credentialProvider: .static(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey),
            httpClientProvider: .createNew
        )
        return S3(
            client: client,
            region: .useast1, // Placeholder, not used for R2 but required
            endpoint: "https://8beac04a4412d942f5236c372570dd70.r2.cloudflarestorage.com"
        )
    }()

    static func uploadVideoToR2(withUrl originalUrl: URL) async throws -> String? {
            let filename = NSUUID().uuidString + ".mov"
            let bucketName = "videos" // Use your actual R2 bucket name

            do {
                let data = try Data(contentsOf: originalUrl)
                let putRequest = S3.PutObjectRequest(body: .data(data), bucket: bucketName, contentType: "video/quicktime", key: filename)
                _ = try await s3Client.putObject(putRequest)
                
                // Construct the URL using the r2.dev domain or your actual domain
                let videoUrl = "https://pub-f0b404514b5d424e9a73685eb0b9f638.r2.dev/\(filename)"
                return videoUrl
            } catch {
                print("DEBUG: Failed to upload video with error: \(error.localizedDescription)")
                throw error
            }
        }
}
