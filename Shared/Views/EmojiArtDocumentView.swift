//
//  ContentView.swift
//  Shared
//
//  Created by Franco Camilletti on 17/03/2022.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        Color.yellow
    }
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
    }
    
    let testEmojis: String = "⛱🗻🗿🚢🚁🏯🏩🎠🚀🏛"
}

struct ScrollingEmojisView: View {
    let emojis: String
    var body: some View {
        
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                }
            }
        }
    }
}



















struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
.previewInterfaceOrientation(.landscapeLeft)
    }
}
