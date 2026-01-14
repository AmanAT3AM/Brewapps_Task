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




