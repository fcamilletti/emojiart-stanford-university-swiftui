//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Franco Camilletti on 17/03/2022.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
