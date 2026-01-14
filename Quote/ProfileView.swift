//
//  ProfileView.swift
//  Quote
//
//  Created for QuoteVault User Profile screen
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showEditProfile = false
    @State private var showChangePassword = false
    @State private var stayLoggedIn: Bool
    
    init() {
        // Initialize stayLoggedIn from authManager
        _stayLoggedIn = State(initialValue: AuthenticationManager().getStayLoggedIn())
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("User Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // User Info Section
                        VStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 80, height: 80)
                                
                                if let user = authManager.currentUser {
                                    Text(String(user.name.prefix(1)).uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.black)
                                } else {
                                    Text("A")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.top, 32)
                            
                            // Name
                            if let user = authManager.currentUser {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                // Email
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Aman Prajpati")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("aman.prajalalis@email.com")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Profile Options
                        VStack(spacing: 0) {
                            ProfileOptionRow(title: "Edit Profile", action: { showEditProfile = true })
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            ProfileOptionRow(title: "Change Password", action: { showChangePassword = true })
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Stay Logged In Toggle
                        HStack {
                            Text("Stay Logged In")
                                .font(.body)
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $stayLoggedIn)
                                .toggleStyle(SwitchToggleStyle(tint: .yellow))
                                .onChange(of: stayLoggedIn) { newValue in
                                    authManager.setStayLoggedIn(newValue)
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Log Out button
                        Button(action: logout) {
                            HStack {
                                Spacer()
                                Text("Log Out")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
                .environmentObject(authManager)
        }
        .onAppear {
            stayLoggedIn = authManager.getStayLoggedIn()
        }
    }
    
    private func logout() {
        authManager.logout()
    }
}

struct ProfileOptionRow: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            .padding()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject({
            let manager = AuthenticationManager()
            manager.currentUser = AuthenticationManager.User(
                id: "1",
                email: "test@example.com",
                name: "Test User"
            )
            manager.isAuthenticated = true
            return manager
        }())
}
