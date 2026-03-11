//
//  QuotesWidget.swift
//  QuotesWidget
//
//  Created by Matthew Hundley on 5/7/24.
//

import WidgetKit
import SwiftUI

private enum SharedQuoteKeys {
    static let appGroupID = "group.com.example.officequotes"
    static let id = "widgetQuote.id"
    static let quote = "widgetQuote.quote"
    static let character = "widgetQuote.character"
    static let avatarURL = "widgetQuote.avatarURL"
}


private struct WidgetQuote: Decodable {
    let id: Int
    let character: String
    let quote: String
    let character_avatar_url: String
}

private struct StoredQuote: Codable, Identifiable, Equatable {
    let id: Int
    let character: String
    let quote: String
    let avatarURL: String
    let fetchedAt: Date
}

private struct QuoteHistoryStore {
    private static let fileName = "quotes-history.json"
    private static let maxStoredQuotes = 500
    private let appGroupID = "group.matthew.hundley.office"

    private var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(Self.fileName)
    }

    func append(_ quote: StoredQuote) {
        var quotes = loadQuotes()
        if quotes.contains(where: { $0.id == quote.id && $0.quote == quote.quote }) {
            return
        }
        quotes.append(quote)
        if quotes.count > Self.maxStoredQuotes {
            quotes.removeFirst(quotes.count - Self.maxStoredQuotes)
        }
        saveQuotes(quotes)
    }

    private func loadQuotes() -> [StoredQuote] {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let quotes = try? JSONDecoder().decode([StoredQuote].self, from: data) else {
            return []
        }
        return quotes
    }

    private func saveQuotes(_ quotes: [StoredQuote]) {
        guard let url = fileURL else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(quotes) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            id: 0,
            quote: "It's Britney, bitch",
            character: "Michael Scott",
            avatarURL: ""
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            date: Date(),
            id: 0,
            quote: "It's Britney, bitch",
            character: "Michael Scott",
            avatarURL: ""
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        Task {
            do {
                // Fetch a random Office quote
                let url = URL(string: "https://officeapi.akashrajpurohit.com/quote/random")!
                let (data, _) = try await URLSession.shared.data(from: url)
                
                let quote = try JSONDecoder().decode(WidgetQuote.self, from: data)
                storeWidgetQuote(quote)
                QuoteHistoryStore().append(
                    StoredQuote(
                        id: quote.id,
                        character: quote.character,
                        quote: quote.quote,
                        avatarURL: quote.character_avatar_url,
                        fetchedAt: Date()
                    )
                )

                // Create a timeline entry with the fetched quote
                let entry = SimpleEntry(
                    date: Date(),
                    id: quote.id,
                    quote: quote.quote,
                    character: quote.character,
                    avatarURL: quote.character_avatar_url
                )

                // Create a timeline with the generated entry
                let timeline = Timeline(entries: [entry], policy: .after(Date.now.addingTimeInterval(900)))
                completion(timeline)
                
            } catch {
                // Handle error
                print("Error fetching data:", error)
            }
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let id: Int
    let quote: String
    let character: String
    let avatarURL: String
}

struct QuotesWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.quote)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: 200)
                .lineLimit(6)
            Divider()

            Text(entry.character)
        }
        .shadow(radius: 15)
        .widgetURL(widgetDeepLink(for: entry))
    }
}

private func widgetDeepLink(for entry: SimpleEntry) -> URL? {
    var components = URLComponents()
    components.scheme = "officequotes"
    components.host = "widgetQuote"
    components.queryItems = [
        URLQueryItem(name: "id", value: String(entry.id)),
        URLQueryItem(name: "quote", value: entry.quote),
        URLQueryItem(name: "character", value: entry.character),
        URLQueryItem(name: "avatarURL", value: entry.avatarURL)
    ]
    return components.url
}

private func storeWidgetQuote(_ quote: WidgetQuote) {
    guard let defaults = UserDefaults(suiteName: SharedQuoteKeys.appGroupID) else {
        return
    }

    defaults.set(quote.id, forKey: SharedQuoteKeys.id)
    defaults.set(quote.quote, forKey: SharedQuoteKeys.quote)
    defaults.set(quote.character, forKey: SharedQuoteKeys.character)
    defaults.set(quote.character_avatar_url, forKey: SharedQuoteKeys.avatarURL)
}

struct QuotesWidget: Widget {
    let kind: String = "QuotesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuotesWidgetEntryView(entry: entry)
                .containerBackground(.blue.gradient.secondary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

//#Preview(as: .systemSmall) {
//    QuotesWidget()
//} timeline: {
//    SimpleEntry(date: .now, quote: "😀")
//    SimpleEntry(date: .now, quote: "🤩")
//}
