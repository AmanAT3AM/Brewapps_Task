//
//  FavoritesView.swift
//  Quote
//
//  Favorites screen
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var quoteService = QuoteService.shared
    
    @State private var favorites: [Quote] = []
    @State private var isLoading = false
    @State private var showShareSheet = false
    @State private var shareQuote: Quote?
    @State private var showQuoteCard = false
    @State private var cardQuote: Quote?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Favorites")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                if isLoading && favorites.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    Spacer()
                } else if favorites.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No favorites yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Start adding quotes to your favorites")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favorites) { quote in
                                FavoriteQuoteCard(
                                    quote: quote,
                                    onRemove: {
                                        removeFavorite(quote: quote)
                                    },
                                    onShare: {
                                        shareQuote = quote
                                        showShareSheet = true
                                    },
                                    onSaveCard: {
                                        cardQuote = quote
                                        showQuoteCard = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await loadFavorites()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadFavorites()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let quote = shareQuote {
                ShareSheet(activityItems: ["\(quote.text) - \(quote.author)"])
            }
        }
        .sheet(isPresented: $showQuoteCard) {
            if let quote = cardQuote {
                QuoteCardView(quote: quote, styleIndex: 0)
            }
        }
    }
    
    private func loadFavorites() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            let fetchedFavorites = try await quoteService.fetchFavorites(userId: userId)
            await MainActor.run {
                favorites = fetchedFavorites
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("Error loading favorites: \(error)")
        }
    }
    
    private func removeFavorite(quote: Quote) {
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                try await quoteService.removeFromFavorites(userId: userId, quoteId: quote.id)
                await MainActor.run {
                    favorites.removeAll { $0.id == quote.id }
                }
            } catch {
                print("Error removing favorite: \(error)")
            }
        }
    }
}

struct FavoriteQuoteCard: View {
    let quote: Quote
    let onRemove: () -> Void
    let onShare: () -> Void
    let onSaveCard: () -> Void
    
    private var fontSize: CGFloat {
        let size = UserDefaults.standard.double(forKey: "quoteFontSize")
        return size > 0 ? size : 16
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(quote.text)
                .font(.system(size: fontSize))
                .foregroundColor(.white)
                .lineSpacing(4)
            
            HStack {
                Text("— \(quote.author)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .italic()
                
                Spacer()
                
                Text(quote.category)
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                Button(action: onRemove) {
                    Image(systemName: "heart.slash")
                        .foregroundColor(.red)
                }
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
                
                Button(action: onSaveCard) {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    FavoritesView()
        .environmentObject({
            let manager = AuthenticationManager()
            manager.currentUser = AuthenticationManager.User(
                id: "1",
                email: "test@example.com",
                name: "Test User"
            )
            manager.isAuthenticated = true
            return manager
        }())
}
