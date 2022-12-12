//
//  ImagesView.swift
//  Cardy
//
//  Created by João Pedro Giarrante on 18/K.radius/22.
//


import SwiftUI

struct ImagesView: View {
    @State private var fullscreen = false
    @State private var fullScreenActiveCardOffset: CGSize = .zero
    @State private var storedActiveCardOffset: CGSize = .zero
    @State var activeCardIndex: Int = .zero
    @State private var manager: ImagesManager
    @Namespace var namespace
    
    // MARK: - Properties
    
    init(with images: [UIImage]) {
        _manager = State(initialValue: ImagesManager(images: images, height: 220))
    }
    
    func getIdealSide() -> CGFloat {
        let side = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        return side
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                    if !fullscreen {
                        ForEach(manager.cards) { card in
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(uiImage: card.image)
                                        .resizable()
                                        .cornerRadius(K.radius)
                                        .shadow(color: K.shadowColor, radius: K.radius, y: K.shadowY)
                                    
                                        // MARK: Effects
                                        .brightness(manager.brightness(for: card))
                                        .offset(manager.offset(for: card))
                                        .scaleEffect(manager.scale(of: card))
                                        .rotationEffect(manager.rotation(for: card))
                                    
                                        // MARK: Gestures
                                        .onTapGesture {
                                            withAnimation(K.spring) {
                                                fullscreen.toggle()
                                            }
                                        }
                                        .gesture(DragGesture()
                                            .onChanged({ drag in
                                                // Manager handles the change in the drag
                                                // Which affect all effects
                                                withAnimation(K.interactiveSpring) {
                                                    manager.onChangedAnimation(with: drag.translation)
                                                }
                                            })
                                                .onEnded({ drag in
                                                    // Manager validates the end translation
                                                    // And moves the card deck index if needed
                                                    withAnimation(K.spring) {
                                                        manager.onEndedAnimation(with: drag.translation)
                                                    }
                                                })
                                        )
                                    
                                        // MARK: Transitions
                                        .matchedGeometryEffect(id: card.id, in: namespace)
                                        .frame(width: K.width, height: K.height)
                                    Spacer()
                                }
                                Spacer()
                                Spacer()
                                Spacer()
                            }
                            .transition(.offset(x: 1, y: 1))
                            .zIndex(manager.zIndex(of: card))
                        }
                    } else {
                        ForEach(manager.cards) { card in
                            VStack {
                                Spacer()
                                Image(uiImage: card.image)
                                    .resizable()
                                
                                    // MARK: Effects
                                    .brightness(manager.brightness(for: card))
                                    .offset(manager.fullScreenOffset(for: card, with: proxy))
                                    .scaleEffect(manager.scale(of: card))
                                
                                    // MARK: Gestures
                                    .onTapGesture {
                                        withAnimation(K.spring) {
                                            fullscreen.toggle()
                                        }
                                    }
                                    .gesture(DragGesture()
                                        .onChanged({ drag in
                                            // Manager handles the change in the drag
                                            // Which affect all effects
                                            withAnimation(K.interactiveSpring) {
                                                manager.onChangedFullscreenAnimation(with: drag)
                                            }
                                        })
                                            .onEnded({ drag in
                                                // Manager validates the end translation
                                                // And moves the card deck index if needed
                                                withAnimation(K.spring) {
                                                    manager.onEndedFullscreenAnimation(with: drag, geometry: proxy)
                                                }
                                            })
                                    )
                                
                                    // MARK: Transitions
                                    .matchedGeometryEffect(id: card.id, in: namespace)
                                    .frame(width: K.screenWidth, height: K.screenWidth/card.aspectRatioMultiplier)
                                Spacer()
                            }
                            .transition(.offset(x: 1, y: 1))
                            .zIndex(manager.zIndex(of: card))
                        }
                }
            }
        }
    }
    
    typealias K = Constants
    
    enum Constants {
        static let height: CGFloat = 220
        static let width: CGFloat = 220
        static let shadowY: CGFloat = 4
        static let radius: CGFloat = 11
        static let shadowColor: Color = .init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.2)
        static let screenWidth = UIScreen.main.bounds.width
        static let topSpacerLenght: CGFloat = 100
        static let bottomSpacerLenght: CGFloat = 500
        static let scaleMultiplier: CGFloat = 0.905
        static let movementMultiplier: CGFloat = 1.5
        static let interactiveSpring: Animation = .interactiveSpring(response: 0.4)
        static let spring: Animation = .spring(blendDuration: 0.4)
    }
}

// MARK: Preview

struct ImagesView_Previews: PreviewProvider {
    static var previews: some View {
        ImagesView(with: [
            .fromColor(UIColor(red: 165/255, green: 226/255, blue: 211/255, alpha: 1)),
            .fromColor(UIColor(red: 248/255, green: 170/255, blue: 158/255, alpha: 1)),
            .fromColor(UIColor(red: 247/255, green: 243/255, blue: 236/255, alpha: 1)),
            .fromColor(UIColor(red: 15/255, green: 41/255, blue: 70/255, alpha: 1))
        ])
        .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
    }
}

// MARK: UIImage+fromColor

extension UIImage {
    public static func fromColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image =  UIGraphicsImageRenderer(size: size, format: format).image { rendererContext in
            color.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
        return image
    }
}

