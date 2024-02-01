//
//  NotificationCellViewModel.swift
//  immerse
//
//

import Foundation

@MainActor
class NotificationCellViewModel: ObservableObject {
    @Published var notification: Notification
    private let userService: UserService

    init(notification: Notification, userService: UserService) {
        self.notification = notification
        self.userService = userService
    }
    
    func follow() {
        guard let uid = notification.user?.id else { return }

        Task {
            try await userService.follow(uid: uid)
            notification.user?.isFollowed = true
            notification.user?.stats.followers += 1
            // Optionally, upload follow notification if needed
            NotificationManager.shared.uploadFollowNotification(toUid: uid)
        }
    }
    
    func unfollow() {
        guard let uid = notification.user?.id else { return }

        Task {
            try await userService.unfollow(uid: uid)
            notification.user?.isFollowed = false
            notification.user?.stats.followers -= 1
        }
    }
}
