//
//  QuotesWidget.swift
//  QuotesWidget
//
//  Created by Matthew Hundley on 5/7/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), quote: "It's Britney, bitch", character: "Michael Scott")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), quote: "It's Britney, bitch", character: "Michael Scott")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        Task {
            do {
                // Fetch a single Office quote
                let quote: OfficeQuote = try await fetchData(from: "https://officeapi.akashrajpurohit.com/quote/random")
                
                // Create a timeline entry with the fetched quote
                let entry = SimpleEntry(date: Date(), quote: quote.quote, character: quote.character)
                
                // Create a timeline with the generated entry
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
            } catch {
                // Handle error
                print("Error fetching data:", error)
            }
        }
    }
    
    func fetchData<T: Decodable>(from urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        return try await URLSession.shared.decode(from: url)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let quote: String
    let character: String
}

struct QuotesWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            Color.blue
            VStack {
                Text(entry.quote)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                Text(entry.character)
            }
        }
        .padding()
    }
}

struct QuotesWidget: Widget {
    let kind: String = "QuotesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuotesWidgetEntryView(entry: entry)
                .containerBackground(.blue, for: .widget)
            
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
