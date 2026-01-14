//
//  QuoteCardView.swift
//  Quote
//
//  Quote card image generator
//

import SwiftUI

struct QuoteCardView: View {
    let quote: Quote
    @State var styleIndex: Int = 0
    
    @State private var savedImage: UIImage?
    @State private var showSaveSuccess = false
    @Environment(\.dismiss) var dismiss
    
    private let styles: [CardStyle] = [
        CardStyle(
            name: "Classic",
            background: LinearGradient(gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom),
            textColor: .white,
            authorColor: .yellow
        ),
        CardStyle(
            name: "Sunset",
            background: LinearGradient(gradient: Gradient(colors: [Color.orange, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing),
            textColor: .white,
            authorColor: .white.opacity(0.9)
        ),
        CardStyle(
            name: "Ocean",
            background: LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .topLeading, endPoint: .bottomTrailing),
            textColor: .white,
            authorColor: .white.opacity(0.9)
        ),
        CardStyle(
            name: "Minimal",
            background: LinearGradient(gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.1)]), startPoint: .top, endPoint: .bottom),
            textColor: .black,
            authorColor: .gray
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Quote Card")
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
                
                // Style Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<styles.count, id: \.self) { index in
                            Button(action: {
                                styleIndex = index
                            }) {
                                Text(styles[index].name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(styleIndex == index ? Color.yellow : Color.gray.opacity(0.2))
                                    .foregroundColor(styleIndex == index ? .black : .white)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                
                // Card Preview
                GeometryReader { geometry in
                    let style = styles[styleIndex]
                    
                    ZStack {
                        style.background
                            .ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Text(quote.text)
                                .font(.system(size: 24, weight: .medium, design: .serif))
                                .foregroundColor(style.textColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                                .padding(.horizontal, 40)
                            
                            Text("— \(quote.author)")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(style.authorColor)
                                .italic()
                            
                            Spacer()
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: shareCard) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                    
                    Button(action: saveCard) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Save")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .alert("Saved!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Quote card saved to Photos")
        }
    }
    
    private func shareCard() {
        let image = generateCardImage()
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func saveCard() {
        let image = generateCardImage()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showSaveSuccess = true
    }
    
    private func generateCardImage() -> UIImage {
        let style = styles[styleIndex]
        let size = CGSize(width: 1080, height: 1080)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Draw background based on style
            let colors: [UIColor]
            switch styleIndex {
            case 0: // Classic
                colors = [.black, UIColor.gray.withAlphaComponent(0.8)]
            case 1: // Sunset
                colors = [.systemOrange, .systemPink]
            case 2: // Ocean
                colors = [.systemBlue, .cyan]
            case 3: // Minimal
                colors = [.white, UIColor.gray.withAlphaComponent(0.1)]
            default:
                colors = [.black, .gray]
            }
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors.map { $0.cgColor } as CFArray,
                                    locations: nil)!
            context.cgContext.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: size.width, y: size.height),
                                               options: [])
            
            // Draw quote text
            let quoteText = quote.text
            let authorText = "— \(quote.author)"
            
            let quoteAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .medium),
                .foregroundColor: style.textColor.uiColor
            ]
            
            let authorAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 36),
                .foregroundColor: style.authorColor.uiColor
            ]
            
            let quoteAttributedString = NSAttributedString(string: quoteText, attributes: quoteAttributes)
            let authorAttributedString = NSAttributedString(string: authorText, attributes: authorAttributes)
            
            let quoteRect = quoteAttributedString.boundingRect(
                with: CGSize(width: size.width - 160, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            
            let authorRect = authorAttributedString.boundingRect(
                with: CGSize(width: size.width - 160, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            
            let totalHeight = quoteRect.height + authorRect.height + 60
            let startY = (size.height - totalHeight) / 2
            
            quoteAttributedString.draw(
                with: CGRect(x: 80, y: startY, width: size.width - 160, height: quoteRect.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            
            authorAttributedString.draw(
                with: CGRect(x: 80, y: startY + quoteRect.height + 40, width: size.width - 160, height: authorRect.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
        }
    }
}

struct CardStyle {
    let name: String
    let background: LinearGradient
    let textColor: Color
    let authorColor: Color
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}

#Preview {
    QuoteCardView(quote: Quote(id: "1", text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Motivation", createdAt: Date()))
}
