//
//  Models.swift
//  Quote
//
//  Quote data models
//

import Foundation

struct Quote: Identifiable, Codable {
    let id: String
    let text: String
    let author: String
    let category: String
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case author
        case category
        case createdAt = "created_at"
    }
    
    init(id: String, text: String, author: String, category: String, createdAt: Date? = nil) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle UUID as string (Supabase returns UUIDs as strings)
        if let uuidValue = try? container.decode(UUID.self, forKey: .id) {
            id = uuidValue.uuidString
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        text = try container.decode(String.self, forKey: .text)
        author = try container.decode(String.self, forKey: .author)
        category = try container.decode(String.self, forKey: .category)
        
        // Handle date decoding with ISO8601 format
        createdAt = nil
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: dateString)
            }
        }
    }
}

struct UserFavorite: Identifiable, Codable {
    let id: Int?
    let userId: String
    let quoteId: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case quoteId = "quote_id"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        quoteId = try container.decode(String.self, forKey: .quoteId)
        
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? formatter.date(from: dateString.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression))
        } else {
            createdAt = nil
        }
    }
}

struct Collection: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? formatter.date(from: dateString.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression))
        } else {
            createdAt = nil
        }
    }
}

struct CollectionQuote: Identifiable, Codable {
    let id: String
    let collectionId: String
    let quoteId: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case collectionId = "collection_id"
        case quoteId = "quote_id"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        collectionId = try container.decode(String.self, forKey: .collectionId)
        quoteId = try container.decode(String.self, forKey: .quoteId)
        
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? formatter.date(from: dateString.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression))
        } else {
            createdAt = nil
        }
    }
}

struct QuoteWithFavorite: Identifiable {
    let quote: Quote
    var isFavorite: Bool
    var id: String { quote.id }
}

enum QuoteCategory: String, CaseIterable {
    case motivation = "Motivation"
    case love = "Love"
    case success = "Success"
    case wisdom = "Wisdom"
    case humor = "Humor"
    
    var icon: String {
        switch self {
        case .motivation: return "flame.fill"
        case .love: return "heart.fill"
        case .success: return "star.fill"
        case .wisdom: return "brain.head.profile"
        case .humor: return "face.smiling.fill"
        }
    }
}
