//
//  AuthService.swift
//  immerse
//
//

import Foundation
import Firebase

@MainActor
class AuthService {
    @Published var userSession: FirebaseAuth.User?
    
    func updateUserSession() {
        self.userSession = Auth.auth().currentUser
    }
    
    func login(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
        } catch {
            print("DEBUG: Login failed \(error.localizedDescription)")
            throw error
        }
    }
    
    func createUser(email: String, password: String, username: String, fullname: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            let user = User(id: result.user.uid, username: username, email: email, fullname: fullname)
            let userData = try Firestore.Encoder().encode(user)
            
            try await FirestoreConstants.UserCollection.document(result.user.uid).setData(userData)
        } catch {
            print("DEBUG: Failed to create user with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func sendResetPasswordLink(toEmail email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func signout() {
        self.userSession = nil
        try? Auth.auth().signOut()
    }
    
    func deleteAccount() async throws {
            
            do {
                // Delete user from Firebase Auth
                try await Auth.auth().currentUser?.delete()
                
                // Clear the user session to sign out the user in the app
                self.userSession = nil

            } catch {
                print("DEBUG: Failed to delete account \(error.localizedDescription)")
                throw error
            }
        }
    
    func createUserWithApple(uid: String, email: String, username: String, fullname: String) async throws {
            do {
                let user = User(id: uid, username: username, email: email, fullname: fullname)
                let userData = try Firestore.Encoder().encode(user)
                try await FirestoreConstants.UserCollection.document(uid).setData(userData)
            } catch {
                print("DEBUG: Failed to create user with Apple: \(error.localizedDescription)")
                throw error
            }
        }
}
