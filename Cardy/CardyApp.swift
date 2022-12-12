//
//  SwippyApp.swift
//  Cardy
//
//  Created by João Pedro Giarrante on 18/11/22.
//


import SwiftUI

@main
struct SwippyApp: App {var body: some Scene {
        WindowGroup {
            ImagesView(with: [
                .fromColor(UIColor(red: 15/255, green: 41/255, blue: 70/255, alpha: 1)),
                .fromColor(UIColor(red: 165/255, green: 226/255, blue: 211/255, alpha: 1)),
                .fromColor(UIColor(red: 248/255, green: 170/255, blue: 158/255, alpha: 1)),
                .fromColor(UIColor(red: 247/255, green: 243/255, blue: 236/255, alpha: 1)),
                .fromColor(UIColor(red: 15/255, green: 41/255, blue: 70/255, alpha: 1))
            ])
        }
    }
}
