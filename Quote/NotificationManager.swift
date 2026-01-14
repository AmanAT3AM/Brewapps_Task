//
//  NotificationManager.swift
//  Quote
//
//  Local notifications manager
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    func scheduleDailyQuote(time: Date) async {
        // Cancel existing notifications
        cancelNotifications()
        
        // Request permission first
        await requestPermission()
        
        // Get quote of the day
        do {
            let quote = try await QuoteService.shared.fetchQuoteOfTheDay()
            
            // Schedule notification
            let content = UNMutableNotificationContent()
            content.title = "Quote of the Day"
            content.body = "\(quote.text) - \(quote.author)"
            content.sound = .default
            content.badge = 1
            
            // Schedule for the specified time
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "dailyQuote",
                content: content,
                trigger: trigger
            )
            
            try await UNUserNotificationCenter.current().add(request)
            print("Daily quote notification scheduled for \(time)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyQuote"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["dailyQuote"])
    }
    
    func checkPermissionStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
