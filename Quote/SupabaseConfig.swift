//
//  SupabaseConfig.swift
//  Quote
//
//  Supabase Configuration
//

import Foundation

struct SupabaseConfig {
    // Replace these with your actual Supabase project credentials
    static let supabaseURL = "https://rfqtnecnmmwjqxngrjla.supabase.co"
    static let supabaseKey = "sb_publishable_PEW56B5IMUyWC_3oCOOCkg_yty7QlB-"
    
    // For development, you can use environment variables or a config file
    static func getURL() -> String {
//        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
//            return url
//        }
        return supabaseURL
    }
    
    static func getKey() -> String {
//        if let key = ProcessInfo.processInfo.environment["SUPABASE_KEY"] {
//            return key
//        }
        return supabaseKey
    }
}
