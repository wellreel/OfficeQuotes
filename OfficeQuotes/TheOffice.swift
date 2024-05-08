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
    @State var quote: OfficeQuote?
    
    var body: some View {
        NavigationStack {
            VStack {
            if let quote {
                ScrollView {
                    VStack {
                        Text(quote.quote)
                        Divider()
                      
                        AsyncImage(url: URL(string: quote.character_avatar_url)) { image in
                            image.resizable()
                                .scaledToFit()
                        } placeholder: {
                            Text("")
                        }
                    }
                }
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                
            } else {
                ProgressView()
            }
        }
            .navigationTitle("Office Quotes")
            }
            .padding()
            .refreshable {
                do {
                    quote = try await fetchData(from: "https://officeapi.akashrajpurohit.com/quote/random")
                } catch {
                    print(error)
                }
            }
            .task {
                do {
                    quote = try await fetchData(from: "https://officeapi.akashrajpurohit.com/quote/random")
                } catch {
                    print(error)
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

#Preview {
    TheOffice()
}
