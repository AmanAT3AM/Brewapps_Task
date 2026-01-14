//
//  SupabaseClient.swift
//  Quote
//
//  Supabase Client Wrapper
//

import Foundation

// Note: This is a simplified Supabase client wrapper
// In production, use the official Supabase Swift SDK: https://github.com/supabase/supabase-swift
// For now, we'll use URLSession to interact with Supabase REST API

class SupabaseClient {
    static let shared = SupabaseClient()
    
    private let baseURL: String
    private let apiKey: String
    private var accessToken: String?
    
    private init() {
        self.baseURL = SupabaseConfig.getURL()
        self.apiKey = SupabaseConfig.getKey()
        // Load access token from UserDefaults if available
        if let savedToken = UserDefaults.standard.string(forKey: "accessToken") {
            self.accessToken = savedToken
        }
    }
    
    func setAccessToken(_ token: String) {
        self.accessToken = token
        UserDefaults.standard.set(token, forKey: "accessToken")
    }
    
    func clearAccessToken() {
        self.accessToken = nil
        UserDefaults.standard.removeObject(forKey: "accessToken")
    }
    
    // MARK: - Auth Methods
    
    func signUp(email: String, password: String, name: String) async throws -> AuthResponse {
        // Ensure baseURL doesn't have trailing slash
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = URL(string: "\(cleanBaseURL)/auth/v1/signup")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["name": name]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Signup Response Status: \(httpResponse.statusCode)")
            print("Signup Response Body: \(responseString)")
        }
        
        // Supabase signup can return 200 (if email confirmation disabled) or 201 (if enabled)
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            do {
                // Try to decode as standard AuthResponse first
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                if let token = authResponse.accessToken {
                    setAccessToken(token)
                }
                return authResponse
            } catch {
                // If standard decoding fails, the response might be just a user object (email confirmation enabled)
                // Try to decode the user directly from the root
                if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check if this is a user object at root level
                    if let userId = jsonDict["id"] as? String {
                        // Extract user metadata
                        var userMetadata: [String: JSONValue]? = nil
                        if let metadataDict = jsonDict["user_metadata"] as? [String: Any] {
                            userMetadata = [:]
                            for (key, value) in metadataDict {
                                if let jsonValue = try? JSONValue.fromAny(value) {
                                    userMetadata?[key] = jsonValue
                                }
                            }
                        }
                        
                        let user = SupabaseUser(
                            id: userId,
                            email: jsonDict["email"] as? String,
                            userMetadata: userMetadata
                        )
                        
                        // If email confirmation is enabled, there's no access token
                        // Check if confirmation was sent
                        let hasConfirmation = jsonDict["confirmation_sent_at"] != nil
                        
                        return AuthResponse(
                            accessToken: nil, // No token when email confirmation is required
                            refreshToken: nil,
                            user: user
                        )
                    }
                }
                
                // If we still can't decode, try to extract error message
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let errorMsg = errorDict["msg"] as? String ?? 
                                  errorDict["message"] as? String ??
                                  errorDict["error_description"] as? String
                    
                    if let msg = errorMsg {
                        throw SupabaseError.apiError(msg)
                    }
                }
                
                throw SupabaseError.apiError("Failed to decode response: \(error.localizedDescription). Response: \(String(data: data, encoding: .utf8) ?? "unknown")")
            }
        } else {
            // Try to decode error response
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let errorMsg = errorDict["msg"] as? String ?? 
                              errorDict["message"] as? String ?? 
                              errorDict["error_description"] as? String ??
                              "Sign up failed with status \(httpResponse.statusCode)"
                
                // Also check for error field
                if let errorField = errorDict["error"] as? String {
                    throw SupabaseError.apiError("\(errorField): \(errorMsg)")
                }
                throw SupabaseError.apiError(errorMsg)
            } else if let responseString = String(data: data, encoding: .utf8) {
                throw SupabaseError.apiError("Sign up failed: \(responseString)")
            } else {
                throw SupabaseError.apiError("Sign up failed with status \(httpResponse.statusCode)")
            }
        }
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Signin Response Status: \(httpResponse.statusCode)")
            print("Signin Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                if let token = authResponse.accessToken {
                    setAccessToken(token)
                }
                return authResponse
            } catch {
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = errorDict["msg"] as? String ?? errorDict["message"] as? String {
                    throw SupabaseError.apiError(errorMsg)
                }
                throw SupabaseError.apiError("Failed to decode response: \(error.localizedDescription)")
            }
        } else {
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let errorMsg = errorDict["msg"] as? String ?? 
                              errorDict["message"] as? String ?? 
                              errorDict["error_description"] as? String ??
                              "Sign in failed with status \(httpResponse.statusCode)"
                
                if let errorField = errorDict["error"] as? String {
                    throw SupabaseError.apiError("\(errorField): \(errorMsg)")
                }
                throw SupabaseError.apiError(errorMsg)
            } else {
                throw SupabaseError.apiError("Sign in failed with status \(httpResponse.statusCode)")
            }
        }
    }
    
    func resetPassword(email: String) async throws {
        let url = URL(string: "\(baseURL)/auth/v1/recover")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            let error = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data)
            throw SupabaseError.apiError(error?.message ?? "Password reset failed")
        }
    }
    
    // MARK: - Database Methods
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        let url = URL(string: "\(baseURL)/rest/v1/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Prefer")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            return try JSONDecoder().decode(T.self, from: data)
        } else {
            let error = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data)
            throw SupabaseError.apiError(error?.message ?? "Request failed")
        }
    }
    
    func requestArray<T: Decodable>(_ endpoint: String, method: String = "GET", body: [String: Any]? = nil) async throws -> [T] {
        // Ensure baseURL doesn't have trailing slash
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = URL(string: "\(cleanBaseURL)/rest/v1/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        // Get access token from stored value or instance variable
        let token = accessToken ?? UserDefaults.standard.string(forKey: "accessToken")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Making request to \(endpoint) with token: \(token.prefix(20))...")
        } else {
            print("WARNING: No access token available for request to \(endpoint)")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("Request body: \(bodyString)")
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Status: \(httpResponse.statusCode) for \(endpoint)")
            if httpResponse.statusCode >= 400 {
                print("Error Response: \(responseString)")
            }
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            // Handle empty response - return empty array
            if data.isEmpty {
                print("Empty response received for \(endpoint)")
                return []
            }
            
            // Check if response is an empty array
            if let responseString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if responseString == "[]" || responseString.isEmpty {
                    print("Empty array response for \(endpoint)")
                    return []
                }
            }
            
            do {
                let decoded = try JSONDecoder().decode([T].self, from: data)
                return decoded
            } catch let decodingError {
                // Log the actual response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Decoding error for \(endpoint): \(decodingError)")
                    print("Response body: \(responseString)")
                } else {
                    print("Decoding error: Data is not valid UTF-8")
                }
                
                // If decoding fails, try to extract error message
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let errorMsg = errorDict["message"] as? String ?? 
                                  errorDict["msg"] as? String ??
                                  errorDict["error"] as? String ??
                                  "Failed to decode response"
                    throw SupabaseError.apiError(errorMsg)
                }
                
                // If it's a decoding error and we have some data, show more details
                throw SupabaseError.apiError("Failed to decode response: \(decodingError.localizedDescription)")
            }
        } else {
            // Try to extract error message from response
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let errorMsg = errorDict["message"] as? String ?? 
                              errorDict["msg"] as? String ??
                              errorDict["error"] as? String ??
                              "Request failed with status \(httpResponse.statusCode)"
                throw SupabaseError.apiError(errorMsg)
            } else if let responseString = String(data: data, encoding: .utf8) {
                throw SupabaseError.apiError("Request failed: \(responseString)")
            } else {
                throw SupabaseError.apiError("Request failed with status \(httpResponse.statusCode)")
            }
        }
    }
}

// MARK: - Models

struct AuthResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let user: SupabaseUser?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let userMetadata: [String: JSONValue]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
    }
    
    init(id: String, email: String?, userMetadata: [String: JSONValue]?) {
        self.id = id
        self.email = email
        self.userMetadata = userMetadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        userMetadata = try container.decodeIfPresent([String: JSONValue].self, forKey: .userMetadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(userMetadata, forKey: .userMetadata)
    }
}

enum JSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let b = try? container.decode(Bool.self) { self = .bool(b); return }
        if let n = try? container.decode(Double.self) { self = .number(n); return }
        if let s = try? container.decode(String.self) { self = .string(s); return }
        if let a = try? container.decode([JSONValue].self) { self = .array(a); return }
        if let o = try? container.decode([String: JSONValue].self) { self = .object(o); return }
        throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        case .bool(let b): try container.encode(b)
        case .array(let a): try container.encode(a)
        case .object(let o): try container.encode(o)
        case .null: try container.encodeNil()
        }
    }
    
    // Helper to create JSONValue from Any
    static func fromAny(_ value: Any) -> JSONValue? {
        switch value {
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            return .number(number.doubleValue)
        case let bool as Bool:
            return .bool(bool)
        case let array as [Any]:
            let jsonArray = array.compactMap { fromAny($0) }
            return jsonArray.count == array.count ? .array(jsonArray) : nil
        case let dict as [String: Any]:
            var jsonDict: [String: JSONValue] = [:]
            for (key, val) in dict {
                if let jsonVal = fromAny(val) {
                    jsonDict[key] = jsonVal
                }
            }
            return .object(jsonDict)
        default:
            return nil
        }
    }
}

struct SupabaseErrorResponse: Codable {
    let message: String?
    let error: String?
}

enum SupabaseError: LocalizedError {
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return message
        }
    }
}
