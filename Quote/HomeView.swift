//
//  HomeView.swift
//  Quote
//
//  Home feed with quotes
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var quoteService = QuoteService.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var quotes: [Quote] = []
    @State private var quoteOfTheDay: Quote?
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var authorFilter = ""
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentPage = 0
    @State private var hasMorePages = true
    @State private var showSearch = false
    @State private var showAuthorFilter = false
    @State private var favoriteQuoteIds: Set<String> = []
    @State private var showShareSheet = false
    @State private var shareQuote: Quote?
    @State private var showQuoteCard = false
    @State private var cardQuote: Quote?
    @State private var selectedCardStyle = 0
    @State private var showAddToCollection = false
    @State private var quoteToAdd: Quote?
    
    private let pageSize = 20
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.yellow)
                        Text("QuoteVault")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    Button(action: { showSearch.toggle() }) {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Search Bar
                if showSearch {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search quotes...", text: $searchText)
                                .foregroundColor(.white)
                                .onChange(of: searchText) { _ in
                                    performSearch()
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            TextField("Filter by author...", text: $authorFilter)
                                .foregroundColor(.white)
                                .onChange(of: authorFilter) { _ in
                                    performSearch()
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .transition(.move(edge: .top))
                }
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                            performSearch()
                        }
                        
                        ForEach(QuoteCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category.rawValue
                            ) {
                                selectedCategory = category.rawValue
                                performSearch()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)
                
                // Quote of the Day
                if let quoteOfTheDay = quoteOfTheDay {
                    QuoteOfTheDayCard(quote: quoteOfTheDay)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                
                // Quotes List
                if isLoading && quotes.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    Spacer()
                } else if quotes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No quotes found")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Try adjusting your filters")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(quotes) { quote in
                                QuoteCard(
                                    quote: quote,
                                    isFavorite: favoriteQuoteIds.contains(quote.id),
                                    onFavoriteToggle: {
                                        toggleFavorite(quote: quote)
                                    },
                                    onShare: {
                                        shareQuote = quote
                                        showShareSheet = true
                                    },
                                    onSaveCard: {
                                        cardQuote = quote
                                        showQuoteCard = true
                                    },
                                    onAddToCollection: {
                                        quoteToAdd = quote
                                        showAddToCollection = true
                                    }
                                )
                            }
                            
                            if isLoadingMore {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                                    .padding()
                            } else if hasMorePages {
                                Button(action: loadMoreQuotes) {
                                    Text("Load More")
                                        .foregroundColor(.yellow)
                                        .padding()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await refreshQuotes()
                    }
                }
            }
        }
        .onAppear {
            loadInitialData()
        }
        .sheet(isPresented: $showShareSheet) {
            if let quote = shareQuote {
                ShareSheet(activityItems: ["\(quote.text) - \(quote.author)"])
            }
        }
        .sheet(isPresented: $showQuoteCard) {
            if let quote = cardQuote {
                QuoteCardView(quote: quote, styleIndex: selectedCardStyle)
            }
        }
        .sheet(isPresented: $showAddToCollection) {
            if let quote = quoteToAdd {
                SelectCollectionView(quote: quote)
                    .environmentObject(authManager)
            }
        }
    }
    
    private func loadInitialData() {
        Task {
            await loadQuoteOfTheDay()
            await refreshQuotes()
            await loadFavorites()
        }
    }
    
    private func loadQuoteOfTheDay() async {
        do {
            quoteOfTheDay = try await quoteService.fetchQuoteOfTheDay()
        } catch {
            print("Error loading quote of the day: \(error)")
        }
    }
    
    private func refreshQuotes() async {
        currentPage = 0
        hasMorePages = true
        isLoading = true
        
        do {
            let newQuotes = try await quoteService.fetchQuotes(
                page: 0,
                limit: pageSize,
                category: selectedCategory,
                searchText: searchText.isEmpty ? nil : searchText,
                author: authorFilter.isEmpty ? nil : authorFilter
            )
            
            await MainActor.run {
                quotes = newQuotes
                hasMorePages = newQuotes.count == pageSize
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("Error loading quotes: \(error)")
        }
    }
    
    private func performSearch() {
        Task {
            await refreshQuotes()
        }
    }
    
    private func loadMoreQuotes() {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        Task {
            do {
                let newQuotes = try await quoteService.fetchQuotes(
                    page: currentPage,
                    limit: pageSize,
                    category: selectedCategory,
                    searchText: searchText.isEmpty ? nil : searchText,
                    author: authorFilter.isEmpty ? nil : authorFilter
                )
                
                await MainActor.run {
                    quotes.append(contentsOf: newQuotes)
                    hasMorePages = newQuotes.count == pageSize
                    isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    isLoadingMore = false
                }
                print("Error loading more quotes: \(error)")
            }
        }
    }
    
    private func loadFavorites() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        do {
            let favorites = try await quoteService.fetchFavorites(userId: userId)
            await MainActor.run {
                favoriteQuoteIds = Set(favorites.map { $0.id })
            }
        } catch {
            print("Error loading favorites: \(error)")
        }
    }
    
    private func toggleFavorite(quote: Quote) {
        guard let userId = authManager.currentUser?.id else { return }
        
        let isCurrentlyFavorite = favoriteQuoteIds.contains(quote.id)
        
        Task {
            do {
                if isCurrentlyFavorite {
                    try await quoteService.removeFromFavorites(userId: userId, quoteId: quote.id)
                    await MainActor.run {
                        favoriteQuoteIds.remove(quote.id)
                    }
                } else {
                    try await quoteService.addToFavorites(userId: userId, quoteId: quote.id)
                    await MainActor.run {
                        favoriteQuoteIds.insert(quote.id)
                    }
                }
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.yellow : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(20)
        }
    }
}

struct QuoteOfTheDayCard: View {
    let quote: Quote
    
    private var fontSize: CGFloat {
        let size = UserDefaults.standard.double(forKey: "quoteFontSize")
        return size > 0 ? size : 16
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                Text("Quote of the Day")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(quote.text)
                .font(.system(size: fontSize))
                .foregroundColor(.white)
                .lineSpacing(4)
            
            Text("— \(quote.author)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .italic()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.yellow.opacity(0.2), Color.yellow.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct QuoteCard: View {
    let quote: Quote
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onShare: () -> Void
    let onSaveCard: () -> Void
    let onAddToCollection: () -> Void
    
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
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                }
                
                Button(action: onAddToCollection) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.yellow)
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager())
}
