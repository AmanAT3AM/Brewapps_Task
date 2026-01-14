//
//  EditProfileView.swift
//  Quote
//
//  Created for QuoteVault Edit Profile screen
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Edit Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
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
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        .padding(.top, 32)
                        
                        // Save button
                        Button(action: saveProfile) {
                            HStack {
                                Spacer()
                                Text("Save")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                        .padding(.top, 32)
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
        .onAppear {
            name = authManager.currentUser?.name ?? ""
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty else {
            errorMessage = "Please enter a name"
            showError = true
            return
        }
        
        Task {
            await authManager.updateProfile(name: name)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject({
            let manager = AuthenticationManager()
            manager.currentUser = AuthenticationManager.User(
                id: "1",
                email: "test@example.com",
                name: "Test User"
            )
            return manager
        }())
}
