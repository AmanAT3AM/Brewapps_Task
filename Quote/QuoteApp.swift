//
//  QuoteApp.swift
//  Quote
//
//  Created by Aman on 13/01/26.
//

import SwiftUI

@main
struct QuoteApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
