//
//  ImagesManager.swift
//  ImagesManager
//
//  Created by João Pedro Giarrante on 03/08/21.
//


import SwiftUI

/// This is the model for the `ImagesView`.
public struct ImagesManager {
    // MARK: - Initializers
    /// Initializer for `ImagesManager`, a model used in swiftUI Multiple Images component.
    public init(images: [UIImage], height: CGFloat) {
        cards = images.compactMap { ImageCard(image: $0) }
        self.height = height
    }

    // MARK: - Properties
    @ObservedObject private var cardProperties = CardProperties()

    var cards: [ImageCard]

    var activeCardIndex: Int {
        return cardProperties.activeCardIndex
    }

    var activeCard: ImageCard {
        return cards[safe: cardProperties.activeCardIndex] ?? cards[0]
    }

    private let height: CGFloat
    private var lastDragGestureCompensatingValue: CGFloat = .zero
    private var fullScreenActiveCardOffset: CGSize = .zero
    private var storedActiveCardOffset: CGSize = .zero
    private var movementDistance: CGFloat {
        return height * Constants.movementHeightMultiplier
    }

    /// Indicates if activeCard is being swiped to `left`.
    private var isSwipingLeft: Bool {
        return storedActiveCardOffset.width < 0
    }

    /// Indicates if activeCard is being swiped to `right`.
    private var isSwipingRight: Bool {
        return storedActiveCardOffset.width > 0
    }

    /// Indicates if the dragging movement from the user reached the maximum distance, enough to perform an swipe.
    private var isDistantEnoughToSwipe: Bool {
        let actualDistance = storedActiveCardOffset.width * Constants.movementMultiplier
        return abs(actualDistance) > movementDistance
    }
}

// MARK: - Mutating API

extension ImagesManager {
    // MARK: Transitions
    mutating func transitionCards(_ direction: CardTransitionDirection) {
        switch direction {
        case .left:
            let nextIndex = cardProperties.activeCardIndex + 1
            guard nextIndex < cards.count else { return }
            cardProperties.activeCardIndex = nextIndex
        case .right:
            let previousIndex = cardProperties.activeCardIndex - 1
            guard previousIndex >= 0 else { return }
            cardProperties.activeCardIndex = previousIndex
        case .start:
            cardProperties.activeCardIndex = 0
        }
        storedActiveCardOffset = .zero
        fullScreenActiveCardOffset = .zero
    }

    mutating func transitionCards(newIndex: Int) {
        cardProperties.activeCardIndex = newIndex
        storedActiveCardOffset = .zero
    }

    // MARK: Animations
    mutating func onChangedAnimation(with dragTranslation: CGSize) {
        // If drag is not valid, animation shouldn't exist
        if !validateDrag(dragTranslation) { return }

        // Show dragging animation
        cardProperties.isSwiping = true

        // Update stored value
        storedActiveCardOffset = dragTranslation
    }

    mutating func onEndedAnimation(with dragTranslation: CGSize) {
        cardProperties.isSwiping = false
        if storedActiveCardOffset.width * Constants.movementMultiplier < -movementDistance {
            transitionCards(.left)
        } else if storedActiveCardOffset.width * Constants.movementMultiplier > movementDistance {
            transitionCards(.right)
        }
        storedActiveCardOffset = .zero
    }
    
    mutating func onChangedFullscreenAnimation(with drag: DragGesture.Value) {
        fullScreenActiveCardOffset = drag.translation
    }
    
    mutating func onEndedFullscreenAnimation(with drag: DragGesture.Value, geometry: GeometryProxy) {
        if abs(fullScreenActiveCardOffset.width) > geometry.size.width*0.5 {
            if drag.translation.width > 0 {
                transitionCards(.right)
            } else {
                transitionCards(.left)
            }
        }
        fullScreenActiveCardOffset = .zero
    }
}

// MARK: - Public API
extension ImagesManager {
    // MARK: Constants
    /// Multiple Images View Static Constants
    enum Constants {
        static let greyColor: Color = .init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)
        static let radius: CGFloat = 11
        static let shadowY: CGFloat = 4
        static let lineWidth: CGFloat = 0.5
        static let slowSpringAnimation: Animation = .spring(response: 0.6)
        static let scaleMultiplier: CGFloat = 0.905
        static let movementMultiplier: CGFloat = 1.5
        static let movementHeightMultiplier: CGFloat = 0.6
        static let dragGestureMinimumValue: CGFloat = 25
    }
    
    // MARK: Helpers
    /// Returns the direction of the `transition`, related to the center of the component view.
    enum CardTransitionDirection {
        case left
        case right
        case start
    }

    /// Returns the position of the `backCard` related to the top active middle card.
    enum PositionRelativeToActive {
        case left
        case right
    }

    /// Returns the index of an `Card`.
    func index(of card: ImageCard?) -> Int {
        guard let safeCard = card, let index = cards.firstIndex(of: safeCard) else { return 0 }
        return index + 1
    }

    // MARK: Cards Brightness
    /// Returns the brightness of an `Card` based on its potision and the opacity logic.
    func brightness(for card: ImageCard) -> Double {
        let index = relativeIndex(of: card)
        let percentageMovement = getActiveCardOffsetPercentage()
        let position = relativePosition(of: card)
        /*
         Each card is 3% more opaque than the one above it, to create a depth feeling.
         `percentageMovement` is used to create an progressive transition between dephts.
         */
        var opacity = 1.0
        let opacityMultiplier = 0.07
        if card != activeCard && (position == .right && isSwipingLeft || position == .left && isSwipingRight) {
            opacity = Double((index - percentageMovement) * opacityMultiplier)
        } else {
            opacity = Double((index + percentageMovement) * opacityMultiplier)
        }
        return -opacity
    }

    func topCardSize(verticalSizeClass: UserInterfaceSizeClass) -> CGSize {
        let width = height * activeCard.aspectRatioMultiplier
        return CGSize(width: width, height: height)
    }

    // MARK: Cards zIndex
    /// Returns the zIndex of an `Card` based on its potision and the priority logic.
    func zIndex(of card: ImageCard) -> Double {
        enum ZIndexPriority {
            static let high: Int = 99999
            static let medium: Int = 9999
            static let low: Int = 999
        }

        if card == activeCard {
            // Active Card is always medium.
            return Double(ZIndexPriority.high)
        } else {
            // This way we block both the side items to swipe:
            if isDistantEnoughToSwipe {
                if let previousCard = cards[safe: cardProperties.activeCardIndex - 1], isSwipingRight && card == previousCard {
                    return Double(ZIndexPriority.high)
                } else if let nextCard = cards[safe: cardProperties.activeCardIndex + 1], isSwipingLeft && card == nextCard {
                    return Double(ZIndexPriority.high)
                }
            }

            // Returns the index compairing to the position
            var rightAditionalIndex = 0
            var leftAditionalIndex = 0

            if isSwipingRight {
                rightAditionalIndex = -ZIndexPriority.low
            } else if isSwipingLeft {
                leftAditionalIndex = -ZIndexPriority.low
            }

            let indexFloat = cards.count - Int(relativeIndex(of: card))
            let position = relativePosition(of: card)

            switch position {
            case .left:
                return Double(indexFloat + leftAditionalIndex)
            case .right:
                return Double(indexFloat + rightAditionalIndex)
            }
        }
    }

    // MARK: Cards Scale
    func scale(of card: ImageCard) -> CGFloat {
        if card == activeCard {
            return activeCardScale()

        } else {
            return backCardsScale(for: card)
        }
    }

    // MARK: Cards Offset
    func offset(for card: ImageCard) -> CGSize {
        if card == activeCard {
            return activeCardOffset()
        } else {
            return CGSize(width: backCardsOffset(for: card), height: 0)
        }
    }
    
    func fullScreenOffset(for card: ImageCard, with geometry: GeometryProxy) -> CGSize {
        /*
         This makes sure that each image has an offSet of its width, multiplied by its index.
         That creates the swiping animation in fullscreen mode.
         */
        return CGSize(width: (CGFloat((index(of: card) - cardProperties.activeCardIndex)-1) * UIScreen.main.bounds.size.width) + fullScreenActiveCardOffset.width, height: 0)
    }

    // MARK: Cards Rotation
    func rotation(for card: ImageCard) -> Angle {
        if card == activeCard {
            return activeCardRotation()
        } else {
            return backCardsRotation(for: card)
        }
    }
}

// MARK: - Private API
private extension ImagesManager {
    // MARK: Helpers
    /// `ScreenMode`, that indicates the possible state of the component.
    enum ScreenMode {
        static let product = "Product"
    }

    /// Returns the index of a `Card`, relative to the active card.
    /// e.g.:
    /// If the card of index `3` is active,
    /// the ones with index `2` and `4` would have an `relativeIndex` equal to `1`.
    func relativeIndex(of card: ImageCard) -> CGFloat {
        let relative = index(of: card) - cardProperties.activeCardIndex
        return CGFloat(relative > 0 ? abs(relative) - 1 : abs(relative) + 1)
    }

    /// Returns the "side" of the `Card`, that indicates if it is in the right or in the left compaired to the `activeCard`.
    func relativePosition(of card: ImageCard) -> PositionRelativeToActive {
        if (index(of: card) - cardProperties.activeCardIndex) > 0 {
            return .right
        } else {
            return .left
        }
    }

    /// Returns the correct `offset` width of the active card, compensating the extra width, after ther dragging movement reaches the necessary width to perfom an slide.
    /// This creates the animation of the cards swiping to the back of the previous one, just like an cheap.
    func getWidthCompensatingExtraMovement() -> CGFloat {
        let currentOffsetWidth = storedActiveCardOffset.width * Constants.movementMultiplier
        let extraOffsetWidth = abs(currentOffsetWidth) - movementDistance
        if extraOffsetWidth > movementDistance { return 0 }
        let finalOffSideWidth = movementDistance - extraOffsetWidth
        return isSwipingRight ? finalOffSideWidth : -finalOffSideWidth
    }

    /// Returns a value between `1` and `0` that represents how close is the current `storedActiveCardOffset` width to the maximum active card width.
    func getActiveCardOffsetPercentage() -> CGFloat {
        if abs(storedActiveCardOffset.width) < movementDistance {
            return abs(storedActiveCardOffset.width) / movementDistance
        } else {
            return 1
        }
    }

    /// Indicates if the dragging movement of the user should reflect on the card offset.
    func validateDrag(_ dragTranslation: CGSize) -> Bool {
        // The last item should not bounce to the left.
        let lastItemDraggingLeft = activeCard == cards.last && dragTranslation.width < 0
        // The first item should not bounce to the right.
        let firstItemDraggingRight = activeCard == cards.first && dragTranslation.width > 0
        /*
         When dragging an activeCard, after reaching more than 1.5x the needed width to perform an swipe movement,
         we start ignoring the dragging to it won't re-appear in the other side.
         */
        let outLimitsDrag = (abs(dragTranslation.width) > movementDistance)
        return !(firstItemDraggingRight || lastItemDraggingLeft || outLimitsDrag)
    }

    // MARK: Cards Scale
    /// Returns the scale of the active card. The scale is inversely proportional to `offSet` width.
    func activeCardScale() -> CGFloat {
        let activeCardOffset = storedActiveCardOffset.width * Constants.movementMultiplier
        let halfOffset = abs(activeCardOffset / 2)
        let maximumOffSetToSwipe = movementDistance
        /*
         The minimum scale will be 0.5.
         It will happen when the card is in the exact maximum distance from the origin.
         In this case, halfOffset/maximumOffSetToSwipe will equal 0.5.
         Other than this case, halfOffset/maximumOffSetToSwipe will result
         on a number lower than 0.5, and higher or equal to 0.
         */
        let calculatedScale = abs(1 - (halfOffset / maximumOffSetToSwipe))
        if isDistantEnoughToSwipe {
            return 1 - calculatedScale
        } else {
            return calculatedScale
        }
    }

    /// Returns the scale of the back cards. The scale is inversely proportional to `offSet` width of that card, that is proportional to its `relatedIndex`.
    func backCardsScale(for card: ImageCard) -> CGFloat {
        let percentageMovement = getActiveCardOffsetPercentage()
        let cardIndex = CGFloat(relativeIndex(of: card))
        let position = relativePosition(of: card)

        /// Local function that returns the scale of an card, inversely proportional to its `index`.
        func scaleForIndex(_ index: CGFloat) -> CGFloat {
            return pow(Constants.scaleMultiplier, index)
        }

        switch position {
        case .left:
            if isSwipingRight {
                return scaleForIndex(cardIndex - percentageMovement)
            } else {
                return scaleForIndex(cardIndex + percentageMovement)
            }
        case .right:
            if isSwipingRight {
                return scaleForIndex(cardIndex + percentageMovement)
            } else {
                return scaleForIndex(cardIndex - percentageMovement)
            }
        }
    }

    // MARK: Cards Offset
    /// Returns the `offSet` of the active card.
    func activeCardOffset() -> CGSize {
        if isDistantEnoughToSwipe {
            let finalOffSideWidth = getWidthCompensatingExtraMovement()
            /*
             The offsetHeight is proportional to the offsetWidth in a 0.4x relation.
             We divide the finalOffSideWidth by the Constants.movementMultiplier before calculating
             because the offsetHeight should not consider the horizontal movement multiplier.
             */
            let finalOffSideHeight = -abs(finalOffSideWidth / Constants.movementMultiplier) * 0.4
            return CGSize(width: finalOffSideWidth, height: finalOffSideHeight)
        } else {
            return CGSize(width: storedActiveCardOffset.width * Constants.movementMultiplier, height: -abs(storedActiveCardOffset.width) * 0.4)
        }
    }

    /// Returns the `offSet` of the back cards. The offset is proportional to its `relativeIndex`.
    func backCardsOffset(for card: ImageCard) -> CGFloat {
        let position = relativePosition(of: card)
        /*
         Each card has an 17% of the activeCard width, times its relativeIndex
         of offSet from the one before.
         e.g.:
         If the activeCard has a width of 200,
         the third card will have (0.17 x 200)x3 in offset.
         */
        let offSetMultiplier = 0.17 * (height)
        var offset = CGFloat(relativeIndex(of: card)) * offSetMultiplier
        let percentageMovement = CGFloat(getActiveCardOffsetPercentage())

        /// Returns `extraOffset` that compensates the width difference from the card to the one above it.
        /// That makes smaller cards appear even if behind a bigger card.
        func extraOffsetCompensatingRatio(for index: Int) -> CGFloat {
            // Sum all extra offsets of the cards above it.
            var sumOffExtrasOffsets: CGFloat = .zero

            let activeCardIndex = self.index(of: activeCard) - 1
            for aCardIndex in min(index, activeCardIndex)...max(index, activeCardIndex) {
                // Ignores top card offset calculus.
                guard aCardIndex != activeCardIndex else { continue }
                guard let aCard = cards[safe: aCardIndex] else { continue }
                let aCardPosition = relativePosition(of: aCard)

                // Get previous card, note that it index depends on card position.
                var aPreviousCardIndex: Int = .zero
                switch aCardPosition {
                case .left:
                    aPreviousCardIndex = aCardIndex + 1
                case .right:
                    aPreviousCardIndex = aCardIndex - 1
                }
                guard let aPreviousCard = cards[safe: aPreviousCardIndex] else { return .zero }

                // Calculate extra offset needed to compensate ratio's width change
                let aDiffer = aPreviousCard.aspectRatioMultiplier - aCard.aspectRatioMultiplier
                let extraOffSet = (aDiffer * height / 2)
                sumOffExtrasOffsets += extraOffSet
            }

            return sumOffExtrasOffsets
        }

        offset += extraOffsetCompensatingRatio(for: index(of: card) - 1)

        if isSwipingRight {
            switch position {
            case .left:
                let finalOffset = offset - (offSetMultiplier * percentageMovement)
                return -finalOffset
            case .right:
                let finalOffset = offset + (offSetMultiplier * percentageMovement)
                return finalOffset
            }
        } else {
            switch position {
            case .left:
                let finalOffset = offset + (offSetMultiplier * percentageMovement)
                return -finalOffset
            case .right:
                let finalOffset = offset - (offSetMultiplier * percentageMovement)
                return finalOffset
            }
        }
    }
    

    // MARK: Cards Rotation
    /// Returns the `Rotation` angle of the active card.
    func activeCardRotation() -> Angle {
        if isDistantEnoughToSwipe {
            return .degrees(Double(getWidthCompensatingExtraMovement() / Constants.movementMultiplier) / 10)
        } else {
            return .degrees(Double(storedActiveCardOffset.width) / 10)
        }
    }

    /// Returns the `Rotation` angle of the back cards. The offset is proportional to its `relativeIndex`.
    /// Each card have an angle of `3 degrees` compaired to the one above it.
    func backCardsRotation(for card: ImageCard) -> Angle {
        let rotationAngle = 3.0
        let position = relativePosition(of: card)

        func rotationForForwardCard(_ card: ImageCard, _ position: PositionRelativeToActive, _ angle: Angle, _ percentageMovement: Double) -> Angle {
            let forwardCardAngle = Angle.degrees(-Double(relativeIndex(of: card) + 1) * rotationAngle)
            let finalCardAngle = degrees + ((degrees - forwardCardAngle) * percentageMovement)
            return finalCardAngle
        }
        func rotationForBackwardCard(_ card: ImageCard, _ position: PositionRelativeToActive, _ angle: Angle, _ percentageMovement: Double) -> Angle {
            let backwardCardAngle = Angle.degrees(-Double(relativeIndex(of: card) + 1) * rotationAngle)
            let finalCardAngle = degrees - ((backwardCardAngle - degrees) * percentageMovement)
            return finalCardAngle
        }
        let percentageMovement = Double(abs(storedActiveCardOffset.width) < movementDistance ? abs(storedActiveCardOffset.width) / movementDistance : 1)
        let degrees = Angle.degrees(-Double(relativeIndex(of: card)) * rotationAngle)
        if isSwipingRight {
            switch position {
            case .left:
                return rotationForForwardCard(card, position, degrees, percentageMovement)
            case .right:
                return -rotationForBackwardCard(card, position, degrees, -percentageMovement)
            }
        } else {
            switch position {
            case .left:
                return rotationForForwardCard(card, position, degrees, -percentageMovement)
            case .right:
                return -rotationForBackwardCard(card, position, degrees, percentageMovement)
            }
        }
    }
}

// MARK: - CardProperties

@MainActor
final class CardProperties: ObservableObject {
    @Published var activeCardIndex: Int = 0
    @Published var isSwiping: Bool = false
}
