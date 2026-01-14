//
//  CollectionsView.swift
//  Quote
//
//  Collections screen
//

import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var quoteService = QuoteService.shared
    
    @State private var collections: [Collection] = []
    @State private var isLoading = false
    @State private var showCreateCollection = false
    @State private var newCollectionName = ""
    @State private var selectedCollection: Collection?
    @State private var showCollectionDetail = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Collections")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    
                    Button(action: { showCreateCollection = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.yellow)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                if isLoading && collections.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    Spacer()
                } else if collections.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No collections yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Create a collection to organize your quotes")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(collections) { collection in
                                CollectionCard(
                                    collection: collection,
                                    onTap: {
                                        selectedCollection = collection
                                        showCollectionDetail = true
                                    },
                                    onDelete: {
                                        deleteCollection(collection: collection)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await loadCollections()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadCollections()
            }
        }
        .sheet(isPresented: $showCreateCollection) {
            CreateCollectionView(
                collectionName: $newCollectionName,
                onSave: {
                    createCollection()
                }
            )
        }
        .sheet(isPresented: $showCollectionDetail) {
            if let collection = selectedCollection {
                CollectionDetailView(collection: collection)
                    .environmentObject(authManager)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadCollections() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            let fetchedCollections = try await quoteService.fetchCollections(userId: userId)
            await MainActor.run {
                collections = fetchedCollections
                isLoading = false
            }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to load collections: \(error.localizedDescription)"
                    showError = true
                }
                print("Error loading collections: \(error)")
            }
    }
    
    private func createCollection() {
        guard !newCollectionName.isEmpty, let userId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                let newCollection = try await quoteService.createCollection(userId: userId, name: newCollectionName)
                await MainActor.run {
                    collections.insert(newCollection, at: 0)
                    newCollectionName = ""
                    showCreateCollection = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create collection: \(error.localizedDescription)"
                    showError = true
                }
                print("Error creating collection: \(error)")
            }
        }
    }
    
    private func deleteCollection(collection: Collection) {
        Task {
            do {
                try await quoteService.deleteCollection(collectionId: collection.id)
                await MainActor.run {
                    collections.removeAll { $0.id == collection.id }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete collection: \(error.localizedDescription)"
                    showError = true
                }
                print("Error deleting collection: \(error)")
            }
        }
    }
}

struct CollectionCard: View {
    let collection: Collection
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let createdAt = collection.createdAt {
                        Text(createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct CreateCollectionView: View {
    @Binding var collectionName: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("New Collection")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collection Name")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("", text: $collectionName)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.top, 32)
                    
                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Create")
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                    .disabled(collectionName.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                
                Spacer()
            }
        }
    }
}

struct CollectionDetailView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var quoteService = QuoteService.shared
    let collection: Collection
    
    @State private var quotes: [Quote] = []
    @State private var isLoading = false
    @State private var showAddQuote = false
    @State private var allQuotes: [Quote] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text(collection.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showAddQuote = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.yellow)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
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
                        Text("No quotes in this collection")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Add quotes to get started")
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
                                    isFavorite: false,
                                    onFavoriteToggle: {},
                                    onShare: {},
                                    onSaveCard: {},
                                    onAddToCollection: {}
                                )
                                .overlay(
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            removeQuote(quote: quote)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.black)
                                                .clipShape(Circle())
                                        }
                                        .padding(8)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await loadCollectionQuotes()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadCollectionQuotes()
                await loadAllQuotes()
            }
        }
        .sheet(isPresented: $showAddQuote) {
            AddQuoteToCollectionView(
                collection: collection,
                availableQuotes: allQuotes,
                currentQuoteIds: Set(quotes.map { $0.id }),
                onQuoteAdded: {
                    // Refresh quotes after adding
                    Task {
                        await loadCollectionQuotes()
                    }
                }
            )
            .environmentObject(authManager)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Quote added to collection successfully!")
        }
    }
    
    private func loadCollectionQuotes() async {
        isLoading = true
        
        do {
            let fetchedQuotes = try await quoteService.fetchCollectionQuotes(collectionId: collection.id)
            await MainActor.run {
                quotes = fetchedQuotes
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load quotes: \(error.localizedDescription)"
                showError = true
            }
            print("Error loading collection quotes: \(error)")
        }
    }
    
    private func loadAllQuotes() async {
        do {
            allQuotes = try await quoteService.fetchQuotes(page: 0, limit: 100)
        } catch {
            print("Error loading all quotes: \(error)")
        }
    }
    
    private func removeQuote(quote: Quote) {
        Task {
            do {
                try await quoteService.removeQuoteFromCollection(collectionId: collection.id, quoteId: quote.id)
                await MainActor.run {
                    quotes.removeAll { $0.id == quote.id }
                }
            } catch {
                print("Error removing quote: \(error)")
            }
        }
    }
}

struct AddQuoteToCollectionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var quoteService = QuoteService.shared
    let collection: Collection
    let availableQuotes: [Quote]
    let currentQuoteIds: Set<String>
    let onQuoteAdded: () -> Void
    
    @State private var searchText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isLoading = false
    @State private var loadedQuotes: [Quote] = []
    @Environment(\.dismiss) var dismiss
    
    var allAvailableQuotes: [Quote] {
        return loadedQuotes.isEmpty ? availableQuotes : loadedQuotes
    }
    
    var filteredQuotes: [Quote] {
        let quotes = allAvailableQuotes.filter { !currentQuoteIds.contains($0.id) }
        
        if searchText.isEmpty {
            return quotes
        } else {
            return quotes.filter { quote in
                quote.text.localizedCaseInsensitiveContains(searchText) ||
                quote.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Add Quotes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                TextField("Search quotes...", text: $searchText)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                if isLoading && filteredQuotes.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    Spacer()
                } else if filteredQuotes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(allAvailableQuotes.isEmpty ? "Loading quotes..." : "No quotes found")
                            .font(.title3)
                            .foregroundColor(.gray)
                        if !searchText.isEmpty {
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        } else if !allAvailableQuotes.isEmpty {
                            Text("All quotes are already in this collection")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredQuotes) { quote in
                                Button(action: {
                                    addQuote(quote: quote)
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(quote.text)
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .lineLimit(3)
                                        
                                        HStack {
                                            Text("— \(quote.author)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            
                                            Spacer()
                                            
                                            Text(quote.category)
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.yellow.opacity(0.2))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Quote added successfully!")
        }
        .onAppear {
            // Load quotes if not already provided
            if availableQuotes.isEmpty {
                loadQuotes()
            } else {
                loadedQuotes = availableQuotes
            }
        }
    }
    
    private func loadQuotes() {
        isLoading = true
        Task {
            do {
                let quotes = try await quoteService.fetchQuotes(page: 0, limit: 100)
                await MainActor.run {
                    loadedQuotes = quotes
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to load quotes: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func addQuote(quote: Quote) {
        Task {
            do {
                try await quoteService.addQuoteToCollection(collectionId: collection.id, quoteId: quote.id)
                await MainActor.run {
                    showSuccess = true
                    onQuoteAdded()
                }
                // Dismiss after a short delay to show success
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add quote: \(error.localizedDescription)"
                    showError = true
                }
                print("Error adding quote: \(error)")
            }
        }
    }
}

struct SelectCollectionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var quoteService = QuoteService.shared
    let quote: Quote
    
    @State private var collections: [Collection] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Add to Collection")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Quote preview
                VStack(alignment: .leading, spacing: 8) {
                    Text(quote.text)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(3)
                    
                    Text("— \(quote.author)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                if isLoading && collections.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    Spacer()
                } else if collections.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No collections yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Create a collection first")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(collections) { collection in
                                Button(action: {
                                    addToCollection(collection: collection)
                                }) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.yellow)
                                            .font(.title3)
                                        
                                        Text(collection.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.yellow)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadCollections()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Quote added to collection!")
        }
    }
    
    private func loadCollections() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            let fetchedCollections = try await quoteService.fetchCollections(userId: userId)
            await MainActor.run {
                collections = fetchedCollections
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load collections: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func addToCollection(collection: Collection) {
        Task {
            do {
                try await quoteService.addQuoteToCollection(collectionId: collection.id, quoteId: quote.id)
                await MainActor.run {
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add quote: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

#Preview {
    CollectionsView()
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
