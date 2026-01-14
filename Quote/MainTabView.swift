//
//  MainTabView.swift
//  Quote
//
//  Created for QuoteVault Main Navigation
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Collections Tab
            CollectionsView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Collections")
                }
            
            // Favorites Tab
            FavoritesView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
            
            // Settings Tab
            SettingsView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
            
            // Profile Tab
            ProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.yellow)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black
            appearance.shadowColor = UIColor.clear
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
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
