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
import VideoToolbox

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
    
    static func compressVideo(sourceUrl: URL, bitrate: Int, completion: @escaping (Result<URL, Error>) -> Void) {
            let asset = AVAsset(url: sourceUrl)
            asset.loadTracks(withMediaType: .video) { videoTracks, videoError in
                guard let videoTrack = videoTracks?.first, videoError == nil else {
                    completion(.failure(videoError ?? NSError(domain: "VideoUploader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load video track"])))
                    return
                }

                let outputUrl = sourceUrl.deletingLastPathComponent().appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
                guard let assetReader = try? AVAssetReader(asset: asset),
                      let assetWriter = try? AVAssetWriter(outputURL: outputUrl, fileType: .mov) else {
                    completion(.failure(NSError(domain: "VideoUploader", code: -3, userInfo: [NSLocalizedDescriptionKey: "AssetReader/Writer initialization failed"])))
                    return
                }

                let videoReaderSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB]

                var videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.hevc,
                    AVVideoHeightKey: videoTrack.naturalSize.height,
                    AVVideoWidthKey: videoTrack.naturalSize.width
                ]

                asset.loadTracks(withMediaCharacteristic: .containsStereoMultiviewVideo) { stereoTracks, stereoError in
                    if let stereoTrack = stereoTracks?.first, stereoError == nil {
                        let MVHEVCVideoLayerIDs = [0, 1] // 0 for left eye, 1 for right eye
                        let multiviewCompressionProperties: [String: Any] = [
                            kVTCompressionPropertyKey_MVHEVCVideoLayerIDs as String: MVHEVCVideoLayerIDs,
                            kVTCompressionPropertyKey_MVHEVCViewIDs as String: MVHEVCVideoLayerIDs,
                            kVTCompressionPropertyKey_MVHEVCLeftAndRightViewIDs as String: MVHEVCVideoLayerIDs,
                            kVTCompressionPropertyKey_HasLeftStereoEyeView as String: true,
                            kVTCompressionPropertyKey_HasRightStereoEyeView as String: true,
                            AVVideoAverageBitRateKey: bitrate
                        ]
                        videoSettings[AVVideoCompressionPropertiesKey] = multiviewCompressionProperties
                    } else {
                        videoSettings[AVVideoCompressionPropertiesKey] = [AVVideoAverageBitRateKey: bitrate]
                    }

                    let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)

                    if assetReader.canAdd(assetReaderVideoOutput) {
                        assetReader.add(assetReaderVideoOutput)
                    } else {
                        completion(.failure(NSError(domain: "VideoUploader", code: -4, userInfo: [NSLocalizedDescriptionKey: "Couldn't add video output reader"])))
                        return
                    }

                    let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                    videoInput.transform = videoTrack.preferredTransform

                    assetWriter.shouldOptimizeForNetworkUse = true
                    assetWriter.add(videoInput)

                    // Check if the asset has an audio track
                    asset.loadTracks(withMediaType: .audio) { audioTracks, audioError in
                        var audioInput: AVAssetWriterInput?
                        var assetReaderAudioOutput: AVAssetReaderTrackOutput?

                        if let audioTrack = audioTracks?.first, audioError == nil {
                            assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)

                            if assetReader.canAdd(assetReaderAudioOutput!) {
                                assetReader.add(assetReaderAudioOutput!)
                            } else {
                                completion(.failure(NSError(domain: "VideoUploader", code: -5, userInfo: [NSLocalizedDescriptionKey: "Couldn't add audio output reader"])))
                                return
                            }

                            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                            assetWriter.add(audioInput!)
                        }

                        assetReader.startReading()
                        assetWriter.startWriting()
                        assetWriter.startSession(atSourceTime: CMTime.zero)

                        let videoInputQueue = DispatchQueue(label: "videoQueue")
                        let audioInputQueue = DispatchQueue(label: "audioQueue")

                        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
                            while videoInput.isReadyForMoreMediaData {
                                if let sample = assetReaderVideoOutput.copyNextSampleBuffer() {
                                    videoInput.append(sample)
                                } else {
                                    videoInput.markAsFinished()
                                    if audioInput == nil || assetReader.status == .completed {
                                        assetWriter.finishWriting {
                                            completion(.success(outputUrl))
                                        }
                                    }
                                    break
                                }
                            }
                        }

                        if let audioInput = audioInput, let assetReaderAudioOutput = assetReaderAudioOutput {
                            audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
                                while audioInput.isReadyForMoreMediaData {
                                    if let sample = assetReaderAudioOutput.copyNextSampleBuffer() {
                                        audioInput.append(sample)
                                    } else {
                                        audioInput.markAsFinished()
                                        if assetReader.status == .completed {
                                            assetWriter.finishWriting {
                                                completion(.success(outputUrl))
                                            }
                                        }
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }


    static func uploadVideoToR2(withUrl originalUrl: URL) async throws -> String? {
            let desiredBitrate = 2500000

            let compressedUrl = try await withCheckedThrowingContinuation { continuation in
                compressVideo(sourceUrl: originalUrl, bitrate: desiredBitrate) { result in
                    switch result {
                    case .success(let url):
                        continuation.resume(returning: url)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            let filename = NSUUID().uuidString + ".mov"
            let bucketName = "videos"

            do {
                let data = try Data(contentsOf: compressedUrl)
                let putRequest = S3.PutObjectRequest(body: .data(data), bucket: bucketName, contentType: "video/quicktime", key: filename)
                _ = try await s3Client.putObject(putRequest)

                let videoUrl = "https://pub-f0b404514b5d424e9a73685eb0b9f638.r2.dev/\(filename)"
                return videoUrl
            } catch {
                print("DEBUG: Failed to upload video with error: \(error.localizedDescription)")
                throw error
            }
        }
}
