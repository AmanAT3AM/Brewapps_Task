//
//  SignUpView.swift
//  Quote
//
//  Created for QuoteVault Sign Up screen
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.yellow)
                        Text("QuoteVault")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Back!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 32)
                        
                        // Input fields
                        VStack(spacing: 20) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                TextField("", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                TextField("", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                SecureField("", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Confirm Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                SecureField("", text: $confirmPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Forgot password link
                            HStack {
                                Spacer()
                                Button(action: {}) {
                                    Text("Forget password?")
                                        .font(.subheadline)
                                        .foregroundColor(.yellow.opacity(0.8))
                                }
                            }
                        }
                        .padding(.top, 32)
                        
                        // Sign Up button
                        Button(action: signUp) {
                            HStack {
                                Spacer()
                                Text("Sign Up Securely")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                        .padding(.top, 32)
                        .disabled(isLoading)
                        
                        // Login link
                        HStack(spacing: 4) {
                            Text("Already have a account?")
                                .foregroundColor(.gray)
                            Button(action: { dismiss() }) {
                                Text("Log in")
                                    .foregroundColor(.yellow)
                                    .fontWeight(.medium)
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }
    
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            let result = await authManager.signUp(email: email, password: password, name: name)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success:
                    // Sign up successful, user is automatically logged in
                    dismiss()
                case .failure(let error):
                    let errorMsg = error.localizedDescription
                    // Check if this is an email confirmation message (not really an error)
                    if errorMsg.contains("check your email") || errorMsg.contains("confirm your account") {
                        successMessage = errorMsg
                        showSuccess = true
                    } else {
                        errorMessage = errorMsg
                        showError = true
                    }
                }
            }
        }
    }
}

// Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthenticationManager())
}
