//
//  UserListService.swift
//  immerse
//
//

import Firebase

class UserListService {
    func fetchUsers() async throws -> [User] {
        return try await FirestoreConstants.UserCollection.getDocuments(as: User.self)
    }
}
