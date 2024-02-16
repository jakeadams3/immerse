//
//  UploadPostViewModel.swift
//  immerse
//
//

import SwiftUI
import Firebase
import PhotosUI

@MainActor
class UploadPostViewModel: ObservableObject {
    @Published var thumbnailImage: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var mediaPreview: Movie?
    @Published var caption = ""
    @Published var selectedMediaForUpload: Movie?
    @Published var showErrorAlert = false
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadVideo(fromItem: selectedItem) } }
    }
    
    private let service: UploadPostService
    
    init(service: UploadPostService) {
        self.service = service
    }
    
    func uploadPost() async {
        guard let videoUrl = selectedMediaForUpload?.url else { return }
        isLoading = true
        
        do {
            let resourceValues = try videoUrl.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resourceValues.fileSize ?? 0
            if fileSize > 15_000_000 {
                self.error = NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Videos cannot be larger than 15MB"])
                self.showErrorAlert = true
                isLoading = false
                return
            }
        } catch {
            self.error = error
            self.showErrorAlert = true
            isLoading = false
            return
        }
        
        do {
            let videoUrlString = try await VideoUploader.uploadVideoToR2(withUrl: videoUrl)
            guard let videoUrlString = videoUrlString else {
                self.error = NSError(domain: "UploadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to upload video to Cloudflare R2"])
                self.showErrorAlert = true
                isLoading = false
                return
            }
            try await service.uploadPost(caption: caption, videoUrlString: videoUrlString)
            isLoading = false
        } catch {
            self.error = error
            self.showErrorAlert = true
            isLoading = false
        }
    }
    
    func setMediaItemForUpload() {
        selectedMediaForUpload = mediaPreview
    }
    
    func reset() {
        caption = ""
        mediaPreview = nil
        error = nil
        selectedItem = nil
        selectedMediaForUpload = nil
    }
    
    func loadVideo(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            guard let movie = try await item.loadTransferable(type: Movie.self) else { return }
            self.mediaPreview = movie
        } catch {
            print("DEBUG: Failed with error \(error.localizedDescription)")
        }
    }
}

extension UploadPostViewModel {
    func loadThumbnail(for movie: Movie) async {
        thumbnailImage = await MediaHelpers.generateThumbnail(path: movie.url.absoluteString)
    }
}
