//
//  CardDetailConfiguration.swift
//  SwipeCardKit
//
//  Created by Antigravity on 28/09/26.
//

import SwiftUI

/// Configuration settings for customizing the appearance, peeking carousel, gestures, and behaviors of the card detail deck.
public struct CardDetailConfiguration: Sendable {
    /// The visible width of previous and next cards peeking from the left and right edges in floating mode. Default is 16.
    public var peekingWidth: CGFloat
    
    /// Spacing between adjacent cards in the floating carousel. Default is 10.
    public var cardSpacing: CGFloat
    
    /// Top padding applied to the floating card from the screen edge. Default is 52 (clears Dynamic Island / status bar).
    public var floatingTopPadding: CGFloat
    
    /// Bottom padding applied to the floating card from the screen edge. Default is 24 (clears home indicator).
    public var floatingBottomPadding: CGFloat
    
    /// Corner radius of the card when in floating state. Default is 28.
    public var floatingCornerRadius: CGFloat
    
    /// Corner radius of the card when in fullscreen state. Default is 24.
    public var fullscreenCornerRadius: CGFloat
    
    /// Scale factor applied to peeking neighbor cards (0.0 to 1.0). Default is 1.0 (cards stand at equal height).
    public var peekingCardScale: CGFloat
    
    /// Opacity applied to peeking neighbor cards (0.0 to 1.0). Default is 0.95.
    public var peekingCardOpacity: Double
    
    /// Opacity of the background dimming layer behind the detail card. Default is 0.65.
    public var dimOpacity: Double
    
    /// Threshold distance in points dragged upwards to expand the card into fullscreen. Default is 45.
    public var swipeUpThreshold: CGFloat
    
    /// Threshold distance in points dragged downwards to dismiss the floating card or collapse fullscreen. Default is 50.
    public var swipeDownThreshold: CGFloat
    
    /// The number of remaining items from the end of the list that triggers `onLoadMore`. Default is 2.
    public var loadMoreThreshold: Int
    
    /// Whether to show the built-in top-left dismiss chevron. Default is true.
    /// Whether to show the built-in frosted backdrop behind the deck. Default is true.
    public var showBackdrop: Bool
    
    public var showDismissChevron: Bool
    
    /// Whether to show a top drag pill handle. Default is false.
    public var showTopGrabber: Bool
    
    /// Whether to show a close button. Default is false.
    public var showCloseButton: Bool
    
    /// The spring response duration used for presentation and mode changes. Default is 0.38.
    public var animationResponse: Double
    
    /// The spring damping fraction used for presentation and mode changes. Default is 0.85.
    public var animationDampingFraction: Double
    
    /// Backward-compatibility accessor for vertical padding.
    public var floatingVerticalPadding: CGFloat {
        get { (floatingTopPadding + floatingBottomPadding) / 2 }
        set {
            floatingTopPadding = newValue
            floatingBottomPadding = newValue
        }
    }
    
    public init(
        peekingWidth: CGFloat = 16,
        cardSpacing: CGFloat = 10,
        floatingTopPadding: CGFloat = 76,
        floatingBottomPadding: CGFloat = 34,
        floatingCornerRadius: CGFloat = 28,
        fullscreenCornerRadius: CGFloat = 24,
        peekingCardScale: CGFloat = 1.0,
        peekingCardOpacity: Double = 0.95,
        dimOpacity: Double = 0.65,
        swipeUpThreshold: CGFloat = 45,
        swipeDownThreshold: CGFloat = 50,
        loadMoreThreshold: Int = 2,
        showDismissChevron: Bool = true,
        showBackdrop: Bool = true,
        showTopGrabber: Bool = false,
        showCloseButton: Bool = false,
        animationResponse: Double = 0.38,
        animationDampingFraction: Double = 0.85
    ) {
        self.peekingWidth = peekingWidth
        self.cardSpacing = cardSpacing
        self.floatingTopPadding = floatingTopPadding
        self.floatingBottomPadding = floatingBottomPadding
        self.floatingCornerRadius = floatingCornerRadius
        self.fullscreenCornerRadius = fullscreenCornerRadius
        self.peekingCardScale = peekingCardScale
        self.peekingCardOpacity = peekingCardOpacity
        self.dimOpacity = dimOpacity
        self.swipeUpThreshold = swipeUpThreshold
        self.swipeDownThreshold = swipeDownThreshold
        self.loadMoreThreshold = loadMoreThreshold
        self.showDismissChevron = showDismissChevron
        self.showBackdrop = showBackdrop
        self.showTopGrabber = showTopGrabber
        self.showCloseButton = showCloseButton
        self.animationResponse = animationResponse
        self.animationDampingFraction = animationDampingFraction
    }
    
    /// Backward-compatible initializer accepting `floatingVerticalPadding`.
    public init(
        peekingWidth: CGFloat = 16,
        cardSpacing: CGFloat = 10,
        floatingVerticalPadding: CGFloat,
        floatingCornerRadius: CGFloat = 28,
        fullscreenCornerRadius: CGFloat = 24,
        peekingCardScale: CGFloat = 1.0,
        peekingCardOpacity: Double = 0.95,
        dimOpacity: Double = 0.65,
        swipeUpThreshold: CGFloat = 45,
        swipeDownThreshold: CGFloat = 50,
        loadMoreThreshold: Int = 2,
        showBackdrop: Bool = true,
        showTopGrabber: Bool = false,
        showCloseButton: Bool = false,
        animationResponse: Double = 0.38,
        animationDampingFraction: Double = 0.85
    ) {
        self.init(
            peekingWidth: peekingWidth,
            cardSpacing: cardSpacing,
            floatingTopPadding: floatingVerticalPadding,
            floatingBottomPadding: floatingVerticalPadding,
            floatingCornerRadius: floatingCornerRadius,
            fullscreenCornerRadius: fullscreenCornerRadius,
            peekingCardScale: peekingCardScale,
            peekingCardOpacity: peekingCardOpacity,
            dimOpacity: dimOpacity,
            swipeUpThreshold: swipeUpThreshold,
            swipeDownThreshold: swipeDownThreshold,
            loadMoreThreshold: loadMoreThreshold,
            showDismissChevron: true,
            showBackdrop: showBackdrop,
            showTopGrabber: showTopGrabber,
            showCloseButton: showCloseButton,
            animationResponse: animationResponse,
            animationDampingFraction: animationDampingFraction
        )
    }
}
