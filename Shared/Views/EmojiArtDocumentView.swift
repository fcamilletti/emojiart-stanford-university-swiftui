//
//  ContentView.swift
//  Shared
//
//  Created by Franco Camilletti on 17/03/2022.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    
    @ObservedObject var document: EmojiArtDocument
    let defaultEmojiFontSize: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0,0), in: geometry))
                )
                .gesture(doubleTapToZoom(in: geometry.size))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: pinchToZoom()))
        }
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found =  providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(EmojiArtModel.Background.url(url.imageURL))
        }
        if !found {
            found =  providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found {
                found = providers.loadObjects(ofType: String.self) { string in
                    if let emoji = string.first, emoji.isEmoji {
                        document.addEmoji(
                            String(emoji),
                            at: convertToEmojiCoordinates(location, in: geometry),
                            size: defaultEmojiFontSize / zoomScale
                    )
                }
            }
        }
        return found
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func pinchToZoom() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    // aca está la data Juan: basicamente la app es una fondo pelado donde podes hacer
    // drag and drop primero de un background desde internet o desde una imagen cualquiera,
    // y luego tenes una paleta de emojis que tambien podes dropear para hacer tu propia obra de arte.
    // aparte del drag and drop estan listos y andando 3 gestos: doble tap para ajustar la imagen al tamaño de la pantalla,
    // un pinch para hacer zoom al fondo, y arrastrar para moverlo.
    // el assignment pide hacer que los emojis sean seleccionables con un tap, y una vez que esten seleccionados poder
    // moverlos, agrandarlos con un pinch o borrarlos. tambien tienen que cancelar la seleccion cuando los volves a tapear una vez.
    // no avance mucho, pero estas lineas de aca abajo son las mias. cree el Set selectedEmojis para que definan cuando un emoji esta
    // seleccionado o no, y usa una funcion creada como extension llamada toggleMembership
    // que se encarga de remover o insertar un Identifiable de un Set (la podes encontrar definida en UtilityExtensions).
    // me trabé porque no se que parametro pasarle a toggleMembership, se que document.emojis es un Array y por eso no va, pero probe de todo
    // y no se si ahi va algo ya existente, o si me falta alguna variable que se defina al momento de clickear el emoji.
    // obviamente el error tambien puede ser otro que no estoy sabiendo ver.
    
    
    var selectedEmojis = Set<EmojiArtModel.Emoji>()
    
    private mutating func oneTapToSelect(in: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                selectedEmojis.toggleMembership(of: document.emojis)
        }
    }
    
    // aca termina lo que escribi, estoy seguro de que es una pavada pero no le encontré la vuelta. sigo mañana temprano
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
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
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
