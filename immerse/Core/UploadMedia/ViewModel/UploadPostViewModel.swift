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
    @Published var showErrorAlert = false // Will be used to trigger the alert
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
        
        // Check if the video file size is under 15MB
        do {
            let resourceValues = try videoUrl.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resourceValues.fileSize ?? 0
            if fileSize > 15_000_000 { // More than 15MB
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
            let videoUrlString = videoUrl.absoluteString
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
