//
//  QuoteApp.swift
//  Quote
//
//  Created by Kavya on 13/01/26.
//

import SwiftUI

@main
struct QuoteApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
