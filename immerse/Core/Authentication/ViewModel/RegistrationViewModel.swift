//
//  RegistrationViewModel.swift
//  immerse
//
//

import Foundation
import AuthenticationServices
import CryptoKit
import Firebase
import FirebaseAuth

class RegistrationViewModel: NSObject, ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullname = ""
    @Published var username = ""
    @Published var isAuthenticating = false
    @Published var showAlert = false
    @Published var authError: AuthError?
    
    private let service: AuthService
    private var currentNonce: String?
    
    init(service: AuthService) {
        self.service = service
        super.init()
    }
    
    @MainActor
    func createUser() async throws {
        isAuthenticating = true
        do {
            try await service.createUser(
                email: email,
                password: password,
                username: username,
                fullname: fullname
            )
            isAuthenticating = false
        } catch {
            let authErrorCode = AuthErrorCode.Code(rawValue: (error as NSError).code)
            showAlert = true
            isAuthenticating = false
            authError = AuthError(authErrorCode: authErrorCode ?? .userNotFound)
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    func checkUsernameExists(username: String, completion: @escaping (String) -> Void) {
        Firestore.firestore().collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                // Handle the error appropriately
                completion(username)
                return
            }
            
            if documents.count > 0 {
                // Username already exists, generate a new one with 11 random digits
                let randomDigits = String(format: "%011d", Int.random(in: 0...99999999999))
                let newUsername = "\(username)\(randomDigits)"
                
                // Recursively call the function with the new username to ensure uniqueness
                self.checkUsernameExists(username: newUsername, completion: completion)
            } else {
                // Username is unique
                completion(username)
            }
        }
    }
    
    private func getUIViewController() -> UIViewController? {
            // Fetch the nearest UIViewController in the SwiftUI view hierarchy.
            UIApplication.shared.windows.first?.rootViewController
        }
}

extension RegistrationViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func startSignInWithAppleFlow() {
            let nonce = randomNonceString()
            currentNonce = nonce
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                guard let authUser = authResult?.user else {
                    print("DEBUG: Unable to retrieve Firebase user")
                    return
                }
                Firestore.firestore().collection("users")
                    .document(authUser.uid).getDocument { document, error in
                        if let error = error {
                            print("DEBUG: Error fetching user: \(error.localizedDescription)")
                            return
                        }
                        if document?.exists == false {
                            let givenName = appleIDCredential.fullName?.givenName ?? ""
                            let familyName = appleIDCredential.fullName?.familyName ?? ""
                            let fullName = "\(givenName) \(familyName)"
                            let usernameNoSpaces = fullName.replacingOccurrences(of: " ", with: "")
                            
                            // Check if the username exists and append digits if necessary
                            self.checkUsernameExists(username: usernameNoSpaces) { finalUsername in
                                Task {
                                    do {
                                        try await self.service.createUserWithApple(
                                            uid: authUser.uid,
                                            email: authUser.email ?? "",
                                            username: finalUsername,
                                            fullname: fullName
                                        )
                                        await self.service.updateUserSession()
                                    } catch {
                                        print("DEBUG: Error creating user with Apple: \(error.localizedDescription)")
                                    }
                                }
                            }
                        } else {
                            print("DEBUG: User already exists")
                            self.service.updateUserSession()
                        }
                    }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
}
