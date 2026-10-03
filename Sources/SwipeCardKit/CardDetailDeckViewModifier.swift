//
//  CardDetailDeckViewModifier.swift
//  SwipeCardKit
//
//  Created by Antigravity on 28/09/26.
//

import SwiftUI

public extension View {
    /// Attaches an interactive card detail deck presentation to the view with shared animation,
    /// horizontal swiping between paginated items, background blur, and swipe-up to fullscreen capability.
    ///
    /// - Parameters:
    ///   - items: A binding to the collection of items (supports live pagination updates).
    ///   - selectedItem: A binding to the currently active/selected item.
    ///   - presentationState: A binding to the presentation state (`.dismissed`, `.floatingCard`, `.fullscreen`).
    ///   - namespace: The shared namespace used for `matchedGeometryEffect` transitions.
    ///   - configuration: Appearance, thresholds, and behavior configuration.
    ///   - onCardFocused: Callback invoked whenever a card becomes active (initial tap or horizontal swipe). Use this to call your detail API.
    ///   - onLoadMore: Callback invoked when swiping near the end of the item collection for pagination.
    ///   - floatingCard: ViewBuilder rendering the floating card contents.
    ///   - fullscreenDetail: ViewBuilder rendering the full scrollable detail page when expanded to fullscreen.
    func cardDetailDeck<Item: Identifiable & Hashable, CardContent: View, DetailContent: View>(
        items: Binding<[Item]>,
        selectedItem: Binding<Item?>,
        presentationState: Binding<CardDetailPresentationState>,
        namespace: Namespace.ID,
        configuration: CardDetailConfiguration = CardDetailConfiguration(),
        onCardFocused: ((Item) -> Void)? = nil,
        onLoadMore: (() -> Void)? = nil,
        onDismissRequested: (() -> Void)? = nil,
        @ViewBuilder floatingCard: @escaping (_ item: Item) -> CardContent,
        @ViewBuilder fullscreenDetail: @escaping (_ item: Item, _ collapse: @escaping () -> Void) -> DetailContent
    ) -> some View {
        self.overlay {
            CardDetailOverlayView(
                items: items,
                selectedItem: selectedItem,
                presentationState: presentationState,
                namespace: namespace,
                configuration: configuration,
                onCardFocused: onCardFocused,
                onLoadMore: onLoadMore,
                onDismissRequested: onDismissRequested,
                floatingCard: floatingCard,
                fullscreenDetail: fullscreenDetail
            )
            .ignoresSafeArea()
        }
    }
    
    /// Attaches an interactive card detail deck presentation to the view with shared animation,
    /// where the presentation state is automatically managed when `selectedItem` is set.
    func cardDetailDeck<Item: Identifiable & Hashable, CardContent: View, DetailContent: View>(
        items: Binding<[Item]>,
        selectedItem: Binding<Item?>,
        namespace: Namespace.ID,
        configuration: CardDetailConfiguration = CardDetailConfiguration(),
        onCardFocused: ((Item) -> Void)? = nil,
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder floatingCard: @escaping (_ item: Item) -> CardContent,
        @ViewBuilder fullscreenDetail: @escaping (_ item: Item, _ collapse: @escaping () -> Void) -> DetailContent
    ) -> some View {
        self.modifier(
            AutoStateCardDetailDeckModifier(
                items: items,
                selectedItem: selectedItem,
                namespace: namespace,
                configuration: configuration,
                onCardFocused: onCardFocused,
                onLoadMore: onLoadMore,
                floatingCard: floatingCard,
                fullscreenDetail: fullscreenDetail
            )
        )
    }
    
    /// Attaches an interactive card detail deck presentation using a single unified content builder
    /// that adapts based on whether the view is currently floating or in fullscreen mode.
    func cardDetailDeck<Item: Identifiable & Hashable, Content: View>(
        items: Binding<[Item]>,
        selectedItem: Binding<Item?>,
        presentationState: Binding<CardDetailPresentationState>,
        namespace: Namespace.ID,
        configuration: CardDetailConfiguration = CardDetailConfiguration(),
        onCardFocused: ((Item) -> Void)? = nil,
        onLoadMore: (() -> Void)? = nil,
        onDismissRequested: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ item: Item, _ isFullscreen: Bool, _ collapse: @escaping () -> Void) -> Content
    ) -> some View {
        self.overlay {
            CardDetailOverlayView(
                items: items,
                selectedItem: selectedItem,
                presentationState: presentationState,
                namespace: namespace,
                configuration: configuration,
                onCardFocused: onCardFocused,
                onLoadMore: onLoadMore,
                onDismissRequested: onDismissRequested,
                detailContent: content
            )
            .ignoresSafeArea()
        }
    }
    
    /// Attaches an interactive card detail deck presentation using a single unified content builder
    /// where presentation state is automatically managed when `selectedItem` is set.
    func cardDetailDeck<Item: Identifiable & Hashable, Content: View>(
        items: Binding<[Item]>,
        selectedItem: Binding<Item?>,
        namespace: Namespace.ID,
        configuration: CardDetailConfiguration = CardDetailConfiguration(),
        onCardFocused: ((Item) -> Void)? = nil,
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ item: Item, _ isFullscreen: Bool, _ collapse: @escaping () -> Void) -> Content
    ) -> some View {
        self.cardDetailDeck(
            items: items,
            selectedItem: selectedItem,
            namespace: namespace,
            configuration: configuration,
            onCardFocused: onCardFocused,
            onLoadMore: onLoadMore,
            floatingCard: { item in
                content(item, false, {})
            },
            fullscreenDetail: { item, collapse in
                content(item, true, collapse)
            }
        )
    }
    
    /// Helper modifier to attach to items in your horizontal row or grid, connecting them
    /// to the shared animation namespace.
    ///
    /// - Parameters:
    ///   - item: The item represented by this card.
    ///   - namespace: The shared `Namespace.ID`.
    ///   - isSelected: Whether this card is currently selected / expanded.
    ///   - isPresented: Whether the detail deck is currently active.
    func cardDetailSource<Item: Identifiable & Hashable>(
        item: Item,
        namespace: Namespace.ID,
        isSelected: Bool,
        isPresented: Bool
    ) -> some View {
        self
    }
}

// MARK: - Internal Automatic State Manager

private struct AutoStateCardDetailDeckModifier<Item: Identifiable & Hashable, CardContent: View, DetailContent: View>: ViewModifier {
    @Binding var items: [Item]
    @Binding var selectedItem: Item?
    let namespace: Namespace.ID
    let configuration: CardDetailConfiguration
    let onCardFocused: ((Item) -> Void)?
    let onLoadMore: (() -> Void)?
    let floatingCard: (Item) -> CardContent
    let fullscreenDetail: (Item, @escaping () -> Void) -> DetailContent
    
    @State private var presentationState: CardDetailPresentationState = .dismissed
    
    func body(content: Content) -> some View {
        content
            .cardDetailDeck(
                items: $items,
                selectedItem: $selectedItem,
                presentationState: $presentationState,
                namespace: namespace,
                configuration: configuration,
                onCardFocused: onCardFocused,
                onLoadMore: onLoadMore,
                floatingCard: floatingCard,
                fullscreenDetail: fullscreenDetail
            )
            .onChange(of: selectedItem) { newItem in
                if newItem != nil && presentationState == .dismissed {
                    withAnimation(
                        .spring(
                            response: configuration.animationResponse,
                            dampingFraction: configuration.animationDampingFraction
                        )
                    ) {
                        presentationState = .floatingCard
                    }
                } else if newItem == nil && presentationState != .dismissed {
                    withAnimation(
                        .spring(
                            response: configuration.animationResponse,
                            dampingFraction: configuration.animationDampingFraction
                        )
                    ) {
                        presentationState = .dismissed
                    }
                }
            }
            .onAppear {
                if selectedItem != nil && presentationState == .dismissed {
                    presentationState = .floatingCard
                }
            }
    }
}
