//
//  RegistrationView.swift
//  immerse
//
//

import SwiftUI

struct RegistrationView: View {
    @StateObject var viewModel: RegistrationViewModel
    private let service: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var showTermsView = false
    
    init(service: AuthService) {
        self.service = service
        self._viewModel = StateObject(wrappedValue: RegistrationViewModel(service: service))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                // logo image
                Image("ClipzyTransparent2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 550, height: 200)
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
                    
                    TextField("Enter your full name", text: $viewModel.fullname)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 750)
                    
                    TextField("Enter your username", text: $viewModel.username)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 750)
                }
                .tint(.white)
                
                Button {
                    Task { try await viewModel.createUser() }
                } label: {
                    Text(viewModel.isAuthenticating ? "" : "Sign up")
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
                
                Text("Or")
                    .font(.headline)
                
                Button {
                    viewModel.startSignInWithAppleFlow()
                } label: {
                    HStack {
                        Image("apple1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Text("Sign in with Apple")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(width: 340, height: 50)
                    .background(Color.black)
                    .clipShape(Capsule())
                }
                .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
                .padding(.vertical)
                
                Spacer()
                
                Button {
                    showTermsView = true
                } label: {
                    Text("By clicking Sign Up, you are agreeing to Clipzy's Terms of Service")
                        .font(.footnote)
                        .foregroundStyle(.white)
                }
                .tint(.clear)
                
                Divider()
                
                NavigationLink {
                    LoginView(service: service)
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack(spacing: 3) {
                        Text("Already have an account?")
                        
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .font(.callout)
                }
                .padding(.vertical, 16)
            }
            .fullScreenCover(isPresented: $showTermsView) {
                NavigationView {
                    TermsView()
                        .navigationBarTitle("Terms of Service", displayMode: .inline)
                        .navigationBarItems(leading: Button(action: {
                            showTermsView = false
                        }) {
                            Image(systemName: "arrow.backward") // Using a system icon for the back button
                                .foregroundStyle(.black)
                        })
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"),
                      message: Text(viewModel.authError?.description ?? ""))
            }
        }
    }
}

// MARK: - Form Validation

extension RegistrationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.email.isEmpty
        && viewModel.email.contains("@")
        && !viewModel.password.isEmpty
        && !viewModel.fullname.isEmpty
        && viewModel.password.count > 5
    }
}

#Preview {
    RegistrationView(service: AuthService())
}
