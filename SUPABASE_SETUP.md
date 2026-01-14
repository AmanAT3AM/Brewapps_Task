# Supabase Database Setup Guide

Follow these steps to set up your Supabase database for QuoteVault:

## Step 1: Open Supabase SQL Editor

1. Go to your Supabase project dashboard
2. Click on **SQL Editor** in the left sidebar
3. Click **New Query**

## Step 2: Run the Schema Script

1. Open the file `supabase_schema.sql` from this project
2. Copy the entire contents
3. Paste it into the Supabase SQL Editor
4. Click **Run** (or press Cmd/Ctrl + Enter)

## Step 3: Verify Tables Were Created

After running the script, you should see:
- A success message: "All tables created successfully!"
- Check the Table Editor to see 4 new tables:
  - `quotes`
  - `user_favorites`
  - `collections`
  - `collection_quotes`

## Step 4: Verify Row Level Security (RLS)

1. Go to **Table Editor** in Supabase
2. For each table (`quotes`, `user_favorites`, `collections`, `collection_quotes`):
   - Click on the table name
   - Click the **Settings** icon (gear icon)
   - Ensure **Enable Row Level Security (RLS)** is checked
   - If not checked, enable it

## Step 5: Verify Policies

The script creates RLS policies automatically. To verify:

1. Go to **Authentication** → **Policies** in Supabase
2. You should see policies for each table:
   - **quotes**: 2 policies (SELECT for everyone, INSERT for authenticated)
   - **user_favorites**: 3 policies (SELECT, INSERT, DELETE for own records)
   - **collections**: 4 policies (SELECT, INSERT, UPDATE, DELETE for own records)
   - **collection_quotes**: 3 policies (SELECT, INSERT, DELETE for own collections)

## Step 6: Verify Sample Data

1. Go to **Table Editor** → **quotes**
2. You should see 100+ quotes across 5 categories:
   - Motivation
   - Love
   - Success
   - Wisdom
   - Humor

## Step 7: Enable Email Authentication

1. Go to **Authentication** → **Providers** in Supabase
2. Find **Email** provider
3. Ensure it's **Enabled**
4. (Optional) Configure email templates if needed

## Troubleshooting

### If you get "policy already exists" errors:
The script now includes `DROP POLICY IF EXISTS` statements, so this shouldn't happen. If it does, you can safely ignore those errors.

### If tables don't appear:
1. Refresh the Table Editor
2. Check the SQL Editor for any error messages
3. Make sure you have the correct permissions in Supabase

### If RLS is not enabled:
1. Manually enable it in Table Editor → Settings for each table
2. The policies should still work once RLS is enabled

### If you see permission errors when using the app:
1. Verify the user is logged in (check access token)
2. Check that RLS policies are correctly set up
3. Verify the access token is being sent in API requests (check console logs)

## Quick Test

After setup, test by:
1. Logging into the app
2. Creating a collection
3. Adding a quote to favorites
4. Adding a quote to a collection

If these work, your database is set up correctly!

## Database Schema Overview

### Tables:

1. **quotes** - Stores all quotes (public read, authenticated write)
2. **user_favorites** - User's favorite quotes (user-specific)
3. **collections** - User-created collections (user-specific)
4. **collection_quotes** - Junction table linking quotes to collections

### Security:

- All tables have Row Level Security (RLS) enabled
- Users can only access their own favorites and collections
- Quotes are publicly readable but only authenticated users can create them
- All operations require authentication (except reading quotes)
