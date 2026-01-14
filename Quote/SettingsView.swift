//
//  SettingsView.swift
//  Quote
//
//  Settings screen
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var selectedTheme: AppTheme = .dark
    @State private var selectedAccentColor: AccentColor = .yellow
    @State private var fontSize: Double = 16
    @State private var notificationEnabled = false
    @State private var notificationTime = Date()
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Theme Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            // Theme Toggle
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Theme")
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    Spacer()
                                    Picker("Theme", selection: $selectedTheme) {
                                        ForEach(AppTheme.allCases, id: \.self) { theme in
                                            Text(theme.rawValue).tag(theme)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 200)
                                }
                                
                                HStack {
                                    Text("Accent Color")
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    Spacer()
                                    Picker("Accent", selection: $selectedAccentColor) {
                                        ForEach(AccentColor.allCases, id: \.self) { color in
                                            Text(color.rawValue).tag(color)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            .padding()
                            .background(themeManager.currentTheme.cardColor)
                            .cornerRadius(12)
                        }
                        
                        // Font Size Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quote Display")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Font Size")
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    Spacer()
                                    Text("\(Int(fontSize))pt")
                                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                                }
                                
                                Slider(value: $fontSize, in: 12...24, step: 1)
                                    .tint(themeManager.currentTheme.accentColor)
                                
                                // Preview
                                Text("Preview: \"The only way to do great work is to love what you do.\"")
                                    .font(.system(size: fontSize))
                                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                                    .italic()
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(themeManager.currentTheme.cardColor)
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(themeManager.currentTheme.cardColor)
                            .cornerRadius(12)
                        }
                        
                        // Notifications Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            VStack(spacing: 12) {
                                Toggle("Daily Quote Notifications", isOn: $notificationEnabled)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                    .onChange(of: notificationEnabled) { enabled in
                                        if enabled {
                                            Task {
                                                await notificationManager.requestPermission()
                                                await notificationManager.scheduleDailyQuote(time: notificationTime)
                                            }
                                        } else {
                                            notificationManager.cancelNotifications()
                                        }
                                    }
                                
                                if notificationEnabled {
                                    DatePicker("Notification Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                        .onChange(of: notificationTime) { newTime in
                                            Task {
                                                await notificationManager.scheduleDailyQuote(time: newTime)
                                            }
                                        }
                                }
                            }
                            .padding()
                            .background(themeManager.currentTheme.cardColor)
                            .cornerRadius(12)
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Version")
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    Spacer()
                                    Text("1.0.0")
                                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                                }
                                
                                HStack {
                                    Text("App Name")
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    Spacer()
                                    Text("QuoteVault")
                                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                                }
                            }
                            .padding()
                            .background(themeManager.currentTheme.cardColor)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            selectedTheme = themeManager.currentThemeType
            selectedAccentColor = themeManager.currentAccentColor
            fontSize = UserDefaults.standard.double(forKey: "quoteFontSize")
            if fontSize == 0 {
                fontSize = 16
            }
            notificationEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
            if let savedTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
                notificationTime = savedTime
            }
        }
        .onChange(of: selectedTheme) { newTheme in
            themeManager.setTheme(newTheme)
        }
        .onChange(of: selectedAccentColor) { newColor in
            themeManager.setAccentColor(newColor)
        }
        .onChange(of: fontSize) { newSize in
            UserDefaults.standard.set(newSize, forKey: "quoteFontSize")
        }
        .onChange(of: notificationEnabled) { enabled in
            UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
        }
        .onChange(of: notificationTime) { newTime in
            UserDefaults.standard.set(newTime, forKey: "notificationTime")
        }
    }
}

enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case auto = "Auto"
}

enum AccentColor: String, CaseIterable {
    case yellow = "Yellow"
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
    case red = "Red"
    
    var color: Color {
        switch self {
        case .yellow: return .yellow
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .red: return .red
        }
    }
}

struct Theme {
    let backgroundColor: Color
    let textColor: Color
    let cardColor: Color
    let accentColor: Color
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme
    @Published var currentThemeType: AppTheme = .dark
    @Published var currentAccentColor: AccentColor = .yellow
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "Dark"
        let initialThemeType = AppTheme(rawValue: savedTheme) ?? .dark
        
        let savedAccent = UserDefaults.standard.string(forKey: "accentColor") ?? "Yellow"
        let initialAccent = AccentColor(rawValue: savedAccent) ?? .yellow
        
        self.currentThemeType = initialThemeType
        self.currentAccentColor = initialAccent
        self.currentTheme = ThemeManager.buildTheme(type: initialThemeType, accent: initialAccent)
    }
    
    func setTheme(_ theme: AppTheme) {
        currentThemeType = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        currentTheme = ThemeManager.buildTheme(type: theme, accent: currentAccentColor)
    }
    
    func setAccentColor(_ color: AccentColor) {
        currentAccentColor = color
        UserDefaults.standard.set(color.rawValue, forKey: "accentColor")
        currentTheme = ThemeManager.buildTheme(type: currentThemeType, accent: color)
    }
    
    private static func buildTheme(type: AppTheme, accent: AccentColor) -> Theme {
        let isDark: Bool
        switch type {
        case .light:
            isDark = false
        case .dark:
            isDark = true
        case .auto:
            // In a real app, check system appearance
            isDark = true
        }
        
        return Theme(
            backgroundColor: isDark ? .black : .white,
            textColor: isDark ? .white : .black,
            cardColor: isDark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05),
            accentColor: accent.color
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}
