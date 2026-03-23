//
//  File.swift
//  SwipeCardKit
//
//  Created by Sharnabh on 23/03/26.
//

import SwiftUI
import UIKit

@MainActor
final class Configuration<Item: Identifiable> {
    var triggerThreshold: CGFloat = 150
    var minimumDistance: CGFloat = 20
    var animateOnYAxes: Bool = false
    var onSwipeEnd: ((Item, CardSwipeDirection) -> Void)?
    var onThresholdPassed: (() -> Void)?
    var onNoMoreCardsLeft: (() -> Void)?
    let visibleCount = 4
    let screenWidth = { UIScreen.current?.bounds.width ?? 400 }()
}
