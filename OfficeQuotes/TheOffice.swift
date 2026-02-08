//
//  TheOffice.swift
//  Concurrent
//
//  Created by Matthew Hundley on 5/2/24.
//
//
//{"id":13,"character":"Michael Scott","quote":"I love inside jokes. I hope to be a part of one someday.","character_avatar_url":"https://i.gyazo.com/5a3113ead3f3541731bf721d317116df.jpg"}

import SwiftUI

struct OfficeQuote: Decodable, Identifiable {
    let id: Int
    let character: String
    let quote: String
    let character_avatar_url: String
}

struct TheOffice: View {
    @State private var quote: OfficeQuote?
    @State private var suppressNetworkQuote = false

    private enum SharedQuoteKeys {
        static let appGroupID = "group.com.example.officequotes"
        static let id = "widgetQuote.id"
        static let quote = "widgetQuote.quote"
        static let character = "widgetQuote.character"
        static let avatarURL = "widgetQuote.avatarURL"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background
                if let quote {
                    ScrollView {
                        VStack(spacing: 20) {
                            AsyncImage(url: URL(string: quote.character_avatar_url)) { image in
                                image.resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.6), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)

                            VStack(spacing: 12) {
                                Text(quote.quote)
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .multilineTextAlignment(.center)

                                Text("— \(quote.character)")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.25), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: quote.id)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        suppressNetworkQuote = false
                        await fetchQuote()
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button {
                            suppressNetworkQuote = false
                            Task {
                                await fetchQuote()
                            }
                        } label: {
                            Label("New Quote", systemImage: "shuffle")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                        .padding(.bottom, 12)
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("That's what she said...")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .navigationTitle("Office Quotes")
        }
        .task {
            if quote == nil {
                await fetchQuote()
            }
        }
        .onOpenURL { url in
            if url.scheme == "officequotes" {
                suppressNetworkQuote = true
                if !loadWidgetQuoteFromURL(url) {
                    loadWidgetQuoteIfAvailable()
                }
            }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.11, blue: 0.20),
                    Color(red: 0.12, green: 0.20, blue: 0.35),
                    Color(red: 0.16, green: 0.34, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 2)
                .offset(x: -120, y: -180)

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 220, height: 140)
                .rotationEffect(.degrees(18))
                .offset(x: 130, y: 220)
        }
    }

    @MainActor
    func fetchQuote() async {
        do {
            var components = URLComponents(string: "https://officeapi.akashrajpurohit.com/quote/random")!
            components.queryItems = [
                URLQueryItem(name: "t", value: UUID().uuidString)
            ]
            let url = components.url!
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            let (data, _) = try await URLSession.shared.data(for: request)

            let newQuote = try JSONDecoder().decode(OfficeQuote.self, from: data)
            guard !suppressNetworkQuote else {
                return
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                quote = newQuote
            }
        } catch {
            print(error)
        }
    }

    @MainActor
    private func loadWidgetQuoteFromURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            return false
        }

        func value(for name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard let quoteText = value(for: "quote"),
              let character = value(for: "character") else {
            return false
        }

        let id = Int(value(for: "id") ?? "0") ?? 0
        let avatarURL = value(for: "avatarURL") ?? ""
        let newQuote = OfficeQuote(
            id: id,
            character: character,
            quote: quoteText,
            character_avatar_url: avatarURL
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            quote = newQuote
        }
        return true
    }

    @MainActor
    private func loadWidgetQuoteIfAvailable() {
        guard let defaults = UserDefaults(suiteName: SharedQuoteKeys.appGroupID) else {
            suppressNetworkQuote = false
            Task {
                await fetchQuote()
            }
            return
        }
        guard let quoteText = defaults.string(forKey: SharedQuoteKeys.quote),
              let character = defaults.string(forKey: SharedQuoteKeys.character) else {
            suppressNetworkQuote = false
            Task {
                await fetchQuote()
            }
            return
        }

        let id = defaults.integer(forKey: SharedQuoteKeys.id)
        let avatarURL = defaults.string(forKey: SharedQuoteKeys.avatarURL) ?? ""
        let newQuote = OfficeQuote(
            id: id,
            character: character,
            quote: quoteText,
            character_avatar_url: avatarURL
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            quote = newQuote
        }
    }
}

#Preview {
    TheOffice()
}
