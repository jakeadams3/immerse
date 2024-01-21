//
//  MockAuthService.swift
//  immerse
//
//

import Foundation

class MockAuthService: AuthServiceProtocol {
    @Published var didAuthenticateUser = false
    @Published var userSession: String?

    @MainActor
    func login(withEmail email: String, password: String) async throws {
        didAuthenticateUser = true
        self.userSession = NSUUID().uuidString
    }
    
    func createUser(withEmail email: String, password: String, username: String) async throws {
        didAuthenticateUser = true
        self.userSession = NSUUID().uuidString
    }
    
    func signout() {
        didAuthenticateUser = false
        self.userSession = nil 
    }
}
