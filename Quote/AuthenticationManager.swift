//
//  AuthenticationManager.swift
//  Quote
//
//  Created for Aman authentication
//

import Foundation
import SwiftUI
import Combine

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let stayLoggedInKey = "stayLoggedIn"
    private let userEmailKey = "userEmail"
    private let userNameKey = "userName"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"
    
    struct User: Identifiable {
        let id: String
        let email: String
        let name: String
    }
    
    private let supabaseClient = SupabaseClient.shared
    
    init() {
        checkSession()
    }
    
    // Check if user should stay logged in
    private func checkSession() {
        let stayLoggedIn = userDefaults.bool(forKey: stayLoggedInKey)
        if stayLoggedIn {
            if let email = userDefaults.string(forKey: userEmailKey),
               let name = userDefaults.string(forKey: userNameKey),
               let userId = userDefaults.string(forKey: userIdKey),
               let token = userDefaults.string(forKey: accessTokenKey) {
                // Restore user session
                currentUser = User(id: userId, email: email, name: name)
                supabaseClient.setAccessToken(token)
                isAuthenticated = true
            }
        }
    }
    
    // Sign up with email and password
    func signUp(email: String, password: String, name: String) async -> Result<Void, AuthError> {
        // Validate input
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            return .failure(.invalidInput)
        }
        
        guard isValidEmail(email) else {
            return .failure(.invalidEmail)
        }
        
        guard password.count >= 6 else {
            return .failure(.passwordTooShort)
        }
        
        do {
            let authResponse = try await supabaseClient.signUp(email: email, password: password, name: name)
            
            if let user = authResponse.user {
                // Extract name from userMetadata (JSONValue)
                var userName = name
                if let metadata = user.userMetadata,
                   let nameValue = metadata["name"],
                   case .string(let nameString) = nameValue {
                    userName = nameString
                }
                
                // Check if email confirmation is required (no access token means confirmation needed)
                if authResponse.accessToken == nil {
                    // Email confirmation is enabled - user needs to confirm email first
                    return .failure(.apiError("Sign up successful! Please check your email to confirm your account before logging in."))
                }
                
                // Email confirmation disabled or already confirmed - proceed with login
                currentUser = User(id: user.id, email: user.email ?? email, name: userName)
                
                if let token = authResponse.accessToken {
                    saveSession(token: token, refreshToken: authResponse.refreshToken, userId: user.id, email: user.email ?? email, name: userName)
                }
                
                isAuthenticated = true
                return .success(())
            } else {
                // User object not in response
                return .failure(.apiError("Sign up completed but user data not available. Please check your email for confirmation."))
            }
        } catch {
            if let supabaseError = error as? SupabaseError {
                return .failure(.apiError(supabaseError.localizedDescription))
            }
            return .failure(.apiError(error.localizedDescription))
        }
    }
    
    // Login with email and password
    func login(email: String, password: String) async -> Result<Void, AuthError> {
        guard !email.isEmpty, !password.isEmpty else {
            return .failure(.invalidInput)
        }
        
        guard isValidEmail(email) else {
            return .failure(.invalidEmail)
        }
        
        do {
            let authResponse = try await supabaseClient.signIn(email: email, password: password)
            
            if let user = authResponse.user {
                // Extract name from userMetadata (JSONValue)
                var userName = email.components(separatedBy: "@").first ?? "User"
                if let metadata = user.userMetadata,
                   let nameValue = metadata["name"],
                   case .string(let nameString) = nameValue {
                    userName = nameString
                }
                
                currentUser = User(id: user.id, email: user.email ?? email, name: userName)
                
                if let token = authResponse.accessToken {
                    saveSession(token: token, refreshToken: authResponse.refreshToken, userId: user.id, email: user.email ?? email, name: userName)
                }
                
                isAuthenticated = true
                return .success(())
            } else {
                return .failure(.apiError("Login failed"))
            }
        } catch {
            if let supabaseError = error as? SupabaseError {
                return .failure(.apiError(supabaseError.localizedDescription))
            }
            return .failure(.apiError(error.localizedDescription))
        }
    }
    
    // Logout
    func logout() {
        currentUser = nil
        isAuthenticated = false
        supabaseClient.clearAccessToken()
        userDefaults.removeObject(forKey: userEmailKey)
        userDefaults.removeObject(forKey: userNameKey)
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
        userDefaults.removeObject(forKey: userIdKey)
    }
    
    // Password reset
    func resetPassword(email: String) async -> Result<Void, AuthError> {
        guard isValidEmail(email) else {
            return .failure(.invalidEmail)
        }
        
        do {
            try await supabaseClient.resetPassword(email: email)
            return .success(())
        } catch {
            if let supabaseError = error as? SupabaseError {
                return .failure(.apiError(supabaseError.localizedDescription))
            }
            return .failure(.apiError(error.localizedDescription))
        }
    }
    
    // Update stay logged in preference
    func setStayLoggedIn(_ value: Bool) {
        userDefaults.set(value, forKey: stayLoggedInKey)
        if !value {
            userDefaults.removeObject(forKey: userEmailKey)
            userDefaults.removeObject(forKey: userNameKey)
            userDefaults.removeObject(forKey: accessTokenKey)
            userDefaults.removeObject(forKey: refreshTokenKey)
            userDefaults.removeObject(forKey: userIdKey)
        } else if let user = currentUser {
            saveSession(token: userDefaults.string(forKey: accessTokenKey) ?? "", 
                       refreshToken: userDefaults.string(forKey: refreshTokenKey),
                       userId: user.id, 
                       email: user.email, 
                       name: user.name)
        }
    }
    
    func getStayLoggedIn() -> Bool {
        return userDefaults.bool(forKey: stayLoggedInKey)
    }
    
    // Update user profile
    func updateProfile(name: String) async {
        guard let user = currentUser else { return }
        // Update in Supabase user metadata
        // For now, update locally
        currentUser = User(id: user.id, email: user.email, name: name)
        
        if userDefaults.bool(forKey: stayLoggedInKey) {
            userDefaults.set(name, forKey: userNameKey)
        }
    }
    
    // Save session
    private func saveSession(token: String, refreshToken: String?, userId: String, email: String, name: String) {
        let stayLoggedIn = userDefaults.bool(forKey: stayLoggedInKey)
        if stayLoggedIn {
            userDefaults.set(email, forKey: userEmailKey)
            userDefaults.set(name, forKey: userNameKey)
            userDefaults.set(token, forKey: accessTokenKey)
            if let refresh = refreshToken {
                userDefaults.set(refresh, forKey: refreshTokenKey)
            }
            userDefaults.set(userId, forKey: userIdKey)
        }
    }
    
    // Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

enum AuthError: LocalizedError {
    case invalidInput
    case invalidEmail
    case passwordTooShort
    case userAlreadyExists
    case userNotFound
    case invalidPassword
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please fill in all fields"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort:
            return "Password must be at least 6 characters"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .userNotFound:
            return "No account found with this email"
        case .invalidPassword:
            return "Incorrect password"
        case .apiError(let message):
            return message
        }
    }
}
