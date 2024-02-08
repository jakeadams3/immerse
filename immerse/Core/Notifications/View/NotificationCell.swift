//
//  NotificationCell.swift
//  immerse
//
//

import SwiftUI
import Kingfisher

struct NotificationCell: View {
    @ObservedObject var viewModel: NotificationCellViewModel
    
    var notification: Notification {
        return viewModel.notification
    }
    
    var isFollowed: Bool {
        return notification.user?.isFollowed ?? false
    }
    
    init(notification: Notification, userService: UserService) {
        self.viewModel = NotificationCellViewModel(notification: notification, userService: userService)
    }
    
    var body: some View {
        HStack {
            NavigationLink(value: notification.user) {
                CircularProfileImageView(user: notification.user, size: .large)
                    .padding(.trailing)
                
                HStack {
                    Text(notification.user?.username ?? "")
                        .foregroundStyle(.white)
                        .font(.title2) +
                    
                    Text(notification.type.notificationMessage)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .font(.title2) +
                    
                    Text(" \(notification.timestamp.timestampString())")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.body)
                }
                .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if notification.type == .follow {
                Button(action: {
                    isFollowed ? viewModel.unfollow() : viewModel.follow()
                }, label: {
                    Text(isFollowed ? "Following" : "Follow")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(width: 200, height: 50)
                        .foregroundColor(isFollowed ? .black : .white)
                        .background(isFollowed ? .white : .black)
                        .cornerRadius(40)
                })
            } else {
                if let post = notification.post {
                    KFImage(URL(string: post.thumbnailUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.horizontal, 80)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(80)
        .overlay(
            RoundedRectangle(cornerRadius: 80)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(radius: 5)
    }
}

//#Preview {
//    NotificationCell(notification: DeveloperPreview.notifications[0])
//}
