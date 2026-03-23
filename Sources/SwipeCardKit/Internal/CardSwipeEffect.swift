//
//  File.swift
//  SwipeCardKit
//
//  Created by Sharnabh on 23/03/26.
//

import SwiftUI

struct CardSwipeEffect: ViewModifier {
    let index: Int
    let offset: CGPoint
    let triggerThreshold: CGFloat

    func body(content: Content) -> some View {
        switch index {
case 0:
    let angle = Angle(degrees: Double(offset.x) / 20)
    content
        .offset(x: offset.x, y: offset.y)
        .rotationEffect(angle, anchor: .bottom)
        .zIndex(4)

case 1:
    content
        .scaleEffect(1)
        .offset(y: 0)
        .zIndex(3)

case 2:
    content
        .scaleEffect(1)
        .offset(y: 0)
        .zIndex(2)

case 3:
    content
        .scaleEffect(1)
        .offset(y: 0)
        .zIndex(1)

default:
    content.opacity(0)
}
    }
}
