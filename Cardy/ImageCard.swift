

//
//  ImageCard.swift
//  ImageCard
//
//  Created by João Pedro Giarrante on 08/09/21.
//  Copyright © 2021 Cornershop Inc. All rights reserved.
//

import SwiftUI

/// This is the model for the `ImagesView`.
final class ImageCard: Identifiable, Equatable, ObservableObject {
    // MARK: - Initializer
    init(image: UIImage) {
        identifier = UUID()
        self.image = image
        let aspectRatio = image.size.width / image.size.height
        // Following business rule explained in `Constants` enum:
        aspectRatioMultiplier = max(Constants.minRatioMultiplier, min(Constants.maxRatioMultiplier, aspectRatio))
    }

    // MARK: - Equatable
    static func == (lhs: ImageCard, rhs: ImageCard) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.image == rhs.image && lhs.aspectRatioMultiplier == rhs.aspectRatioMultiplier
    }

    // MARK: - Properties
    @Published var isFullscreenOpen: Bool = false
    let aspectRatioMultiplier: CGFloat
    let image: UIImage

    /// UUID is necessary because we can have duplicated images.
    private let identifier: UUID
}

// MARK: - Private API
private extension ImageCard {
    enum Constants {
        /* Business Rule:
         Max Aspect -> 1:1
         Min Aspect -> 3:4 [width:height] (that gives us 0.75)
         */
        static let maxRatioMultiplier: CGFloat = 1.0
        static let minRatioMultiplier: CGFloat = 0.75
    }
}
