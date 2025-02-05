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
                        AsyncImage(url: URL(string: quote.character_avatar_url)) { image in
                            image.resizable()
                                .frame(maxHeight: 400)
                                .frame(maxWidth: 600)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } placeholder: {
                            Text("")
                        }
                        Divider()
                        Text(quote.quote)
                    }
                }
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                
            } else {
                Text("That's what she said...")
            }
        }
            .navigationTitle("Office Quotes")
            }
            .padding()
            .task(fetchQuote)
            .refreshable {
                await fetchQuote()
            }
    }
    @Sendable func fetchQuote() async {
        do {
            let url = URL(string: "https://officeapi.akashrajpurohit.com/quote/random")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            quote = try JSONDecoder().decode(OfficeQuote.self, from: data)
            
        } catch {
            print(error)
        }
    }
}

#Preview {
    TheOffice()
}
