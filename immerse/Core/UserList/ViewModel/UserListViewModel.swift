//
//  UserListViewModel.swift
//  immerse
//
//

import Foundation

@MainActor
class UserListViewModel: ObservableObject {
    @Published var users = [User]()
    private let service: UserListService
    
    init(service: UserListService) {
        self.service = service
        
        Task { await fetchUsers() }
    }
    
    func fetchUsers() async {
        do {
            self.users = try await service.fetchUsers()
        } catch {
            print("DEBUG: Failed to fetch users with error \(error.localizedDescription)")
        }
    }
}
