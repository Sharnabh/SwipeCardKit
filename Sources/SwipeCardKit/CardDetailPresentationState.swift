//
//  CardDetailPresentationState.swift
//  SwipeCardKit
//
//  Created by Antigravity on 28/09/26.
//

import Foundation

/// Represents the presentation state of a card detail deck.
public enum CardDetailPresentationState: Sendable, Equatable {
    /// The detail card is dismissed and not visible.
    case dismissed
    
    /// The detail card is floating above the screen with margins, background blur,
    /// and horizontal swipe gesture enabled for paging between items.
    case floatingCard
    
    /// The card is expanded to fill the entire screen, with horizontal swipe gestures
    /// disabled and vertical scrolling enabled for full content inspection.
    case fullscreen
    
    /// Returns whether the detail deck is currently presented (floating or fullscreen).
    public var isPresented: Bool {
        self != .dismissed
    }
}
