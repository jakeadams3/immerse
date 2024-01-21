//
//  AuthServiceProtocol.swift
//  immerse
//
//

import Foundation

protocol AuthServiceProtocol {
    func login(withEmail email: String, password: String) async throws
    func createUser(withEmail email: String, password: String, username: String) async throws
    func signout() 
}
