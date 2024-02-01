//
//  LoginView.swift
//  immerse
//
//

import SwiftUI

struct LoginView: View {
    private let service: AuthService
    @StateObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) var dismiss
    
    init(service: AuthService) {
        self.service = service
        self._viewModel = StateObject(wrappedValue: LoginViewModel(service: service))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                // logo image
                Image("tiktok-app-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding()
                
                // text fields
                VStack(spacing: 16) {
                    TextField("Enter your email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 750)
                    
                    SecureField("Enter your password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 750)
                }
                
                Button {
                    Task {
                        await viewModel.login()
                        dismiss()
                    }
                } label: {
                    Text(viewModel.isAuthenticating ? "" : "Login")
                        .foregroundColor(.white)
                        .overlay {
                            if viewModel.isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                }
                .disabled(viewModel.isAuthenticating || !formIsValid)
                .opacity(formIsValid ? 1 : 0.7)
                
                .padding(.vertical)
                
                Spacer()
                
                Divider()
                
                NavigationLink {
                    RegistrationView(service: service)
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack(spacing: 3) {
                        Text("Don't have an account?")
                        
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                }
                .padding(.vertical, 16)

            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"), 
                      message: Text(viewModel.authError?.description ?? "Please try again.."))
            }
        }
    }
}

extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.email.isEmpty
        && viewModel.email.contains("@")
        && !viewModel.password.isEmpty
    }
}

#Preview {
    LoginView(service: AuthService())
}
