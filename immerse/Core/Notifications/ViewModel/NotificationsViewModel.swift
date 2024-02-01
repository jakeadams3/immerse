//
//  NotificationsViewModel.swift
//  immerse
//
//

import Foundation

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications = [Notification]()
    @Published var isLoading = false
    @Published var showEmptyView = false
    
    private let service: NotificationService
    let userService: UserService // Added UserService instance
    
    init(service: NotificationService, userService: UserService = UserService()) {
        self.service = service
        self.userService = userService // Initialize UserService
        Task { await fetchNotifications() }
    }
    
    func fetchNotifications() async {
        isLoading = true
        do {
            self.notifications = try await service.fetchNotifications()
            self.showEmptyView = notifications.isEmpty
            isLoading = false
        } catch {
            print("DEBUG: Failed to fetch notifications with error \(error.localizedDescription)")
            isLoading = false
        }
    }
}
