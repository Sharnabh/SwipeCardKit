//
//  File.swift
//  SwipeCardKit
//
//  Created by Sharnabh on 23/03/26.
//

import Foundation


public enum CardSwipeDirection: Sendable {
    case left, right, idle
    
    init (offset: CGFloat) {
        if offset > 0 {
            self = .right
        } else if offset == 0 {
            self = .idle
        } else {
            self = .left
        }
    }
}
