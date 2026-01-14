
QuoteVault – Complete Project Documentation
Mobile Application Developer Assignment

1. Project Overview
QuoteVault is a full-featured quote discovery and collection iOS application built using SwiftUI and Supabase.
The app allows users to:
Browse inspirational quotes
Save favorites
Create collections
Personalize the experience
Receive a daily quote notification
This project was developed as part of the “Build a Full-Featured Quote App Using AI Tools” assignment, with a strong focus on:
Feature completeness
Clean architecture
Polished UI/UX
Effective AI-assisted development workflow

2. Objectives of the Assignment
The primary objectives of this project were:
Build a production-quality mobile app
Implement authentication, cloud sync, and personalization
Demonstrate effective use of AI tools during development
Deliver clean, maintainable, and scalable code
Provide clear documentation and setup instructions

3. Technology Stack
Frontend
SwiftUI – Declarative UI framework
Combine – Reactive state management
WidgetKit (Planned / Optional) – Home screen widget support
Backend
Supabase
Authentication (Email & Password)
PostgreSQL Database
Row Level Security (RLS)
Native iOS APIs
UserNotifications – Daily quote notifications
PhotosUI – Saving quote cards
ShareSheet – Sharing quotes

5. Database Design
Tables Used
quotes
user_favorites
collections
collection_quotes
Security
Row Level Security enabled on all tables
Policies restrict access to authenticated users only

6. AI Tools & Workflow (Critical Evaluation Area)
AI Tools Used
ChatGPT – Architecture, SwiftUI patterns, Supabase queries
GitHub Copilot – Code completion & refactoring
Cursor / Claude Code – Debugging and optimization
Figma Make / Stitch – UI design generation
Workflow
Feature breakdown using AI
Generate SwiftUI view structure
Validate Supabase schema with AI
Debug async & state issues using AI prompts
Optimize UI/UX polish
AI was used as a development accelerator, not a replacement for core engineering judgment.

Setup & Configuration Guide
STEP 1️⃣ Create a Supabase Project
Go to https://supabase.com
Sign up / Login
Click New Project
Fill details:
Project name
Password
Region (closest to you)
Click Create Project
Wait 1–2 minutes

STEP 2️⃣ Get Supabase Credentials
After the project is ready:
Go to Project Settings → API
Copy the following:
Project URL
Anon Public Key

STEP 4️⃣ Add Supabase SDK (Swift Package Manager)
Supabase supports Swift Package Manager (SPM).
In Xcode:
Click File → Add Packages
Paste the following URL:
https://github.com/supabase/supabase-swift
Click Add Package
Select Supabase
Click Finish

STEP 5️⃣ Create Supabase Client
Create a new Swift file:
📁 SupabaseClient.swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://YOUR_PROJECT_ID.supabase.co")!,
    supabaseKey: "YOUR_ANON_PUBLIC_KEY"
)

⚠️ Replace:
YOUR_PROJECT_ID
YOUR_ANON_PUBLIC_KEY

STEP 6️⃣ Enable Email Auth (Supabase Dashboard)
Go to Supabase Dashboard → Authentication
Navigate to Providers
Enable Email
Click Save

STEP 9️⃣ Create Table in Supabase
Go to Supabase Dashboard → Table Editor
Create table (example):
users
id (uuid, primary key)
name (text)
email (text)


Design Screenshot:


![WhatsApp Image 2026-01-13 at 5 43 05 PM (1)](https://github.com/user-attachments/assets/f25b7545-3c35-41a8-b1d7-be0dac9f1962)


![WhatsApp Image 2026-01-13 at 5 43 05 PM](https://github.com/user-attachments/assets/38ebc7ec-392c-4a05-a0a8-f1a39b27ff72)


End of Document

# QuoteVault - Full-Featured Quote App

A complete quote discovery and collection app built with SwiftUI and Supabase, featuring user accounts, cloud sync, and personalization.

## Features

### ✅ Authentication & User Accounts
- Sign up with email/password
- Login/logout functionality
- Password reset flow
- User profile screen (name, avatar)
- Session persistence (stay logged in)
- Integrated with Supabase Auth

### ✅ Quote Browsing & Discovery
- Home feed displaying quotes with pagination
- Browse quotes by category (Motivation, Love, Success, Wisdom, Humor)
- Search quotes by keyword
- Search/filter by author
- Pull-to-refresh functionality
- Loading states and empty states handled gracefully
- 100+ pre-seeded quotes across categories

### ✅ Favorites & Collections
- Save quotes to favorites (heart/bookmark)
- View all favorited quotes in a dedicated screen
- Create custom collections (e.g., "Morning Motivation", "Work Quotes")
- Add/remove quotes from collections
- Cloud sync — favorites persist across devices when logged in

### ✅ Daily Quote & Notifications
- "Quote of the Day" prominently displayed on home screen
- Quote of the day changes daily (server-side logic)
- Local push notification for daily quote
- User can set preferred notification time in settings

### ✅ Sharing & Export
- Share quote as text via system share sheet
- Generate shareable quote card (quote + author on styled background)
- Save quote card as image to device
- 4 different card styles/templates to choose from (Classic, Sunset, Ocean, Minimal)

### ✅ Personalization & Settings
- Dark mode / Light mode toggle
- 5 accent colors to choose from (Yellow, Blue, Purple, Green, Red)
- Font size adjustment for quotes (12-24pt)
- Settings persist locally and sync to user profile

## Setup Instructions

### 1. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to SQL Editor in your Supabase dashboard
3. Run the SQL script from `supabase_schema.sql` to create all necessary tables and policies
4. Go to Authentication > Providers and enable Email authentication
5. Copy your project URL and anon key from Settings > API

### 2. Configure the App

1. Open `Quote/SupabaseConfig.swift`
2. Replace the placeholder values:
   ```swift
   static let supabaseURL = "YOUR_SUPABASE_URL"
   static let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
   ```

### 3. Build and Run

1. Open `Quote.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘R)

### 4. Permissions

The app requires the following permissions:
- **Notifications**: For daily quote notifications (requested when enabling in settings)
- **Photo Library**: For saving quote cards (requested when saving a card)

## Project Structure

```
Quote/
├── QuoteApp.swift              # App entry point
├── AuthenticationManager.swift # Auth state management
├── SupabaseClient.swift        # Supabase API client
├── SupabaseConfig.swift        # Supabase configuration
├── Models.swift                # Data models
├── QuoteService.swift          # Quote data service
├── NotificationManager.swift   # Local notifications
├── ThemeManager.swift          # Theme management
├── Views/
│   ├── LoginView.swift
│   ├── SignUpView.swift
│   ├── ForgotPasswordView.swift
│   ├── HomeView.swift
│   ├── FavoritesView.swift
│   ├── CollectionsView.swift
│   ├── ProfileView.swift
│   ├── EditProfileView.swift
│   ├── ChangePasswordView.swift
│   ├── SettingsView.swift
│   ├── QuoteCardView.swift
│   └── MainTabView.swift
└── supabase_schema.sql         # Database schema
```

## Database Schema

The app uses the following Supabase tables:
- `quotes` - Stores all quotes
- `user_favorites` - User's favorite quotes
- `collections` - User-created collections
- `collection_quotes` - Junction table for quotes in collections

All tables have Row Level Security (RLS) enabled with appropriate policies.

## Technologies Used

- **SwiftUI** - UI framework
- **Supabase** - Backend (Auth + Database)
- **UserNotifications** - Local push notifications
- **Core Data** - Local persistence (for app data)

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- Active Supabase project

## Notes

- The app includes 100+ pre-seeded quotes across 5 categories
- All user data syncs to Supabase when logged in
- Quote of the Day is selected based on the day of the year
- Quote cards can be saved to Photos or shared via the system share sheet

## Troubleshooting

### Authentication Issues
- Ensure Supabase Auth is enabled in your project
- Check that your Supabase URL and key are correct
- Verify email templates are configured in Supabase dashboard

### Database Issues
- Make sure you've run the `supabase_schema.sql` script
- Check that RLS policies are correctly set up
- Verify your API key has the correct permissions

### Notification Issues
- Ensure notification permissions are granted
- Check that notifications are enabled in device settings
- Verify the notification time is set correctly in app settings

## License

This project is provided as-is for educational purposes.
