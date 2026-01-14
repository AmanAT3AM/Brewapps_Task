//
//  QuoteService.swift
//  Quote
//
//  Service for managing quotes from Supabase
//

import Foundation

class QuoteService: ObservableObject {
    static let shared = QuoteService()
    
    private let supabaseClient = SupabaseClient.shared
    
    // Fetch quotes with pagination
    func fetchQuotes(page: Int = 0, limit: Int = 20, category: String? = nil, searchText: String? = nil, author: String? = nil) async throws -> [Quote] {
        var endpoint = "quotes?order=created_at.desc"
        
        // Add pagination
        let offset = page * limit
        endpoint += "&limit=\(limit)&offset=\(offset)"
        
        // Add category filter
        if let category = category, !category.isEmpty {
            endpoint += "&category=eq.\(category)"
        }
        
        // Add search filter
        if let searchText = searchText, !searchText.isEmpty {
            endpoint += "&text=ilike.%25\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%25"
        }
        
        // Add author filter
        if let author = author, !author.isEmpty {
            endpoint += "&author=ilike.%25\(author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%25"
        }
        
        let quotes: [Quote] = try await supabaseClient.requestArray(endpoint)
        return quotes
    }
    
    // Fetch quote of the day
    func fetchQuoteOfTheDay() async throws -> Quote {
        do {
            // Try to fetch quotes ordered by creation date
            let endpoint = "quotes?order=created_at.desc&limit=1"
            let quotes: [Quote] = try await supabaseClient.requestArray(endpoint)
            
            if let quote = quotes.first {
                return quote
            }
            
            // If no quotes found, try to get any quote
            let allQuotes: [Quote] = try await supabaseClient.requestArray("quotes?limit=1")
            if let quote = allQuotes.first {
                return quote
            }
            
            // Fallback quote if database is empty
            return Quote(id: "1", text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Motivation", createdAt: Date())
        } catch {
            print("Error fetching quote of the day: \(error)")
            // Return fallback quote on error
            return Quote(id: "1", text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Motivation", createdAt: Date())
        }
    }
    
    // Fetch user favorites
    func fetchFavorites(userId: String) async throws -> [Quote] {
        // First get favorite quote IDs
        let favoritesEndpoint = "user_favorites?user_id=eq.\(userId)&select=quote_id"
        let favorites: [UserFavorite] = try await supabaseClient.requestArray(favoritesEndpoint)
        
        guard !favorites.isEmpty else { return [] }
        
        // Then fetch the actual quotes
        let quoteIds = favorites.map { $0.quoteId }.joined(separator: ",")
        let quotesEndpoint = "quotes?id=in.(\(quoteIds))"
        let quotes: [Quote] = try await supabaseClient.requestArray(quotesEndpoint)
        
        return quotes
    }
    
    // Add to favorites
    func addToFavorites(userId: String, quoteId: String) async throws {
        let body: [String: Any] = [
            "user_id": userId,
            "quote_id": quoteId
        ]
        
        let _: [UserFavorite] = try await supabaseClient.requestArray("user_favorites", method: "POST", body: body)
    }
    
    // Remove from favorites
    func removeFromFavorites(userId: String, quoteId: String) async throws {
        let endpoint = "user_favorites?user_id=eq.\(userId)&quote_id=eq.\(quoteId)"
        // Note: Supabase DELETE doesn't return data, so we use a different approach
        let url = URL(string: "\(SupabaseConfig.getURL())/rest/v1/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.getKey(), forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.apiError("Failed to remove favorite")
        }
    }
    
    // Check if quote is favorite
    func isFavorite(userId: String, quoteId: String) async throws -> Bool {
        let endpoint = "user_favorites?user_id=eq.\(userId)&quote_id=eq.\(quoteId)&select=id"
        let favorites: [UserFavorite] = try await supabaseClient.requestArray(endpoint)
        return !favorites.isEmpty
    }
    
    // Fetch collections
    func fetchCollections(userId: String) async throws -> [Collection] {
        let endpoint = "collections?user_id=eq.\(userId)&order=created_at.desc"
        let collections: [Collection] = try await supabaseClient.requestArray(endpoint)
        return collections
    }
    
    // Create collection
    func createCollection(userId: String, name: String) async throws -> Collection {
        let body: [String: Any] = [
            "user_id": userId,
            "name": name
        ]
        
        let collections: [Collection] = try await supabaseClient.requestArray("collections", method: "POST", body: body)
        guard let collection = collections.first else {
            throw SupabaseError.apiError("Failed to create collection")
        }
        return collection
    }
    
    // Delete collection
    func deleteCollection(collectionId: String) async throws {
        let endpoint = "collections?id=eq.\(collectionId)"
        let url = URL(string: "\(SupabaseConfig.getURL())/rest/v1/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.getKey(), forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.apiError("Failed to delete collection")
        }
    }
    
    // Get quotes in collection
    func fetchCollectionQuotes(collectionId: String) async throws -> [Quote] {
        // Get quote IDs from collection
        let collectionQuotesEndpoint = "collection_quotes?collection_id=eq.\(collectionId)&select=quote_id"
        let collectionQuotes: [CollectionQuote] = try await supabaseClient.requestArray(collectionQuotesEndpoint)
        
        guard !collectionQuotes.isEmpty else { return [] }
        
        // Build proper IN query for Supabase PostgREST
        let quoteIds = collectionQuotes.map { $0.quoteId }
        
        // Supabase PostgREST uses parentheses format: id=in.(uuid1,uuid2,uuid3)
        let idsString = quoteIds.joined(separator: ",")
        let quotesEndpoint = "quotes?id=in.(\(idsString))"
        
        do {
            let quotes: [Quote] = try await supabaseClient.requestArray(quotesEndpoint)
            return quotes
        } catch {
            print("Error fetching collection quotes with IN query: \(error)")
            // Fallback: fetch quotes individually if IN query fails
            var fetchedQuotes: [Quote] = []
            for quoteId in quoteIds {
                do {
                    let quoteEndpoint = "quotes?id=eq.\(quoteId)"
                    let quotes: [Quote] = try await supabaseClient.requestArray(quoteEndpoint)
                    fetchedQuotes.append(contentsOf: quotes)
                } catch {
                    print("Error fetching quote \(quoteId): \(error)")
                }
            }
            return fetchedQuotes
        }
    }
    
    // Add quote to collection
    func addQuoteToCollection(collectionId: String, quoteId: String) async throws {
        let body: [String: Any] = [
            "collection_id": collectionId,
            "quote_id": quoteId
        ]
        
        let _: [CollectionQuote] = try await supabaseClient.requestArray("collection_quotes", method: "POST", body: body)
    }
    
    // Remove quote from collection
    func removeQuoteFromCollection(collectionId: String, quoteId: String) async throws {
        let endpoint = "collection_quotes?collection_id=eq.\(collectionId)&quote_id=eq.\(quoteId)"
        let url = URL(string: "\(SupabaseConfig.getURL())/rest/v1/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.getKey(), forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.apiError("Failed to remove quote from collection")
        }
    }
}
