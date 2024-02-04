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
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadVideo(fromItem: selectedItem) } }
    }
    
    private let service: UploadPostService
    
    init(service: UploadPostService) {
        self.service = service
    }
    
    func uploadPost() async {
        guard let videoUrlString = mediaPreview?.url.absoluteString else { return }
        isLoading = true
        
        do {
            try await service.uploadPost(caption: caption, videoUrlString: videoUrlString)
            isLoading = false
        } catch {
            self.error = error
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
