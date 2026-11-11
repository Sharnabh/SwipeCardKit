//
//  CardDetailOverlayView.swift
//  SwipeCardKit
//
//  Created by Antigravity on 28/09/26.
//

import SwiftUI

// MARK: - PreferenceKey for Child Horizontal Scroll Regions
public struct ChildHorizontalScrollRectPreferenceKey: PreferenceKey {
    public static let defaultValue: [CGRect] = []
    public static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

public extension View {
    /// Informs the parent cardDetailDeck or CardDetailOverlayView to not intercept horizontal swiping gestures
    /// when the user drags inside this view (e.g. for variant selectors, unit pickers, or inner horizontal carousels).
    func preventCardDetailSwipe() -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ChildHorizontalScrollRectPreferenceKey.self,
                    value: [geo.frame(in: .global)]
                )
            }
        )
    }
}

@MainActor
public struct CardDetailOverlayView<Item: Identifiable & Hashable, CardContent: View, DetailContent: View>: View {
    @Binding var items: [Item]
    @Binding var selectedItem: Item?
    @Binding var presentationState: CardDetailPresentationState
    
    let namespace: Namespace.ID
    let configuration: CardDetailConfiguration
    let onCardFocused: ((Item) -> Void)?
    let onLoadMore: (() -> Void)?
    var onDismissRequested: (() -> Void)? = nil
    
    private let floatingCard: ((Item) -> CardContent)?
    private let fullscreenDetail: ((Item, _ collapseOrDismiss: @escaping () -> Void) -> DetailContent)?
    private let unifiedDetail: ((Item, _ isFullscreen: Bool, _ collapseOrDismiss: @escaping () -> Void) -> DetailContent)?
    
    @State private var dragOffset: CGSize = .zero
    @State private var lockedAxis: GestureAxis? = nil
    @State private var lastNotifiedItemId: Item.ID?
    @State private var fullscreenDragOffset: CGFloat = 0
    @State private var excludedScrollRects: [CGRect] = []
    
    private enum GestureAxis {
        case horizontal
        case vertical
        case ignored
    }
    
    private var currentIndex: Int {
        if let selectedItem, let idx = items.firstIndex(where: { $0.id == selectedItem.id }) {
            return idx
        }
        return 0
    }
    
    // MARK: - Initializer with separate floating and fullscreen content
    public init(
        items: Binding<[Item]>,
        selectedItem: Binding<Item?>,
        presentationState: Binding<CardDetailPresentationState>,
        namespace: Namespace.ID,
        configuration: CardDetailConfiguration = CardDetailConfiguration(),
        onCardFocused: ((Item) -> Void)? = nil,
        onLoadMore: (() -> Void)? = nil,
        onDismissRequested: (() -> Void)? = nil,
        @ViewBuilder floatingCard: @escaping (Item) -> CardContent,
        @ViewBuilder fullscreenDetail: @escaping (Item, _ collapseOrDismiss: @escaping () -> Void) -> DetailContent
    ) {
        self._items = items
        self._selectedItem = selectedItem
        self._presentationState = presentationState
        self.namespace = namespace
        self.configuration = configuration
        self.onCardFocused = onCardFocused
        self.onLoadMore = onLoadMore
        self.onDismissRequested = onDismissRequested
        self.floatingCard = floatingCard
        self.fullscreenDetail = fullscreenDetail
        self.unifiedDetail = nil
    }

    // MARK: - Initializer with unified detail content builder
    public init(
        items: Binding<[Item]>,
        selectedItem: Binding<Item?>,
        presentationState: Binding<CardDetailPresentationState>,
        namespace: Namespace.ID,
        configuration: CardDetailConfiguration = CardDetailConfiguration(),
        onCardFocused: ((Item) -> Void)? = nil,
        onLoadMore: (() -> Void)? = nil,
        onDismissRequested: (() -> Void)? = nil,
        @ViewBuilder detailContent: @escaping (_ item: Item, _ isFullscreen: Bool, _ collapse: @escaping () -> Void) -> DetailContent
    ) where CardContent == DetailContent {
        self._items = items
        self._selectedItem = selectedItem
        self._presentationState = presentationState
        self.namespace = namespace
        self.configuration = configuration
        self.onCardFocused = onCardFocused
        self.onLoadMore = onLoadMore
        self.onDismissRequested = onDismissRequested
        self.floatingCard = nil
        self.fullscreenDetail = nil
        self.unifiedDetail = detailContent
    }

    public var body: some View {
        GeometryReader { proxy in
            let screenSize = proxy.size
            let cardWidth = max(screenSize.width - (2 * (configuration.peekingWidth + configuration.cardSpacing)), 120)
            let cardHeight = max(screenSize.height - configuration.floatingTopPadding - configuration.floatingBottomPadding, 160)
            let isFullscreen = presentationState == .fullscreen
            let step = isFullscreen ? screenSize.width : (cardWidth + configuration.cardSpacing)
            let centerX = screenSize.width / 2
            let centerY = configuration.floatingTopPadding + (cardHeight / 2)
            
            ZStack {
                if configuration.showBackdrop && presentationState != .dismissed {
                    // Dark blurred backdrop with dynamic dimming on drag-to-dismiss
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Color.black.opacity(
                                isFullscreen
                                    ? 1.0
                                    : (dragOffset.height > 0
                                        ? max(0.15, configuration.dimOpacity * (1.0 - (dragOffset.height / max(screenSize.height * 0.6, 1.0))))
                                        : configuration.dimOpacity)
                            )
                        )
                        .ignoresSafeArea()
                        .opacity(presentationState != .dismissed ? 1.0 : 0.0)
                        .onTapGesture {
                            if presentationState == .floatingCard {
                                dismiss()
                            }
                        }
                        .transition(.opacity)
                }
                
                if presentationState != .dismissed {
                    // Unified Presentation Container (All cards in continuous animated deck)
                    deckContainerView(
                        screenSize: screenSize,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        step: step,
                        centerX: centerX,
                        centerY: centerY,
                        isFullscreen: isFullscreen
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .bottom)
                    ))
                }
            }
            .animation(
                .spring(
                    response: configuration.animationResponse,
                    dampingFraction: configuration.animationDampingFraction
                ),
                value: presentationState
            )
            .onChange(of: selectedItem) { newItem in
                if let newItem, let idx = items.firstIndex(where: { $0.id == newItem.id }) {
                    handleItemActivated(newItem, at: idx)
                }
            }
            .onAppear {
                if let current = selectedItem ?? items.first,
                   let idx = items.firstIndex(where: { $0.id == current.id }) {
                    handleItemActivated(current, at: idx)
                }
            }
            .onPreferenceChange(ChildHorizontalScrollRectPreferenceKey.self) { rects in
                if dragOffset == .zero && self.excludedScrollRects != rects {
                    self.excludedScrollRects = rects
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Deck Container (All Cards in Single Continuous Carousel)
    
    @ViewBuilder
    private func deckContainerView(
        screenSize: CGSize,
        cardWidth: CGFloat,
        cardHeight: CGFloat,
        step: CGFloat,
        centerX: CGFloat,
        centerY: CGFloat,
        isFullscreen: Bool
    ) -> some View {
        let lowerBound = max(0, currentIndex - 1)
        let upperBound = min(items.count - 1, currentIndex + 1)
        
        ZStack {
            ForEach(lowerBound...upperBound, id: \.self) { index in
                let item = items[index]
                let indexDistance = index - currentIndex
                let isCenterCard = index == currentIndex
                
                if abs(indexDistance) <= 1 {
                    let baseOffsetX = CGFloat(indexDistance) * step
                    let currentX = isFullscreen
                        ? (centerX + (CGFloat(indexDistance) * screenSize.width) + dragOffset.width)
                        : (centerX + baseOffsetX + dragOffset.width)
                    let currentY = isFullscreen
                        ? (screenSize.height / 2 + max(0, fullscreenDragOffset))
                        : (centerY + interactiveVerticalOffset)
                    
                    let distanceFromCenter = abs(currentX - centerX) / step
                    let scale = isFullscreen
                        ? 1.0
                        : (isCenterCard ? 1.0 : max(1.0 - (1.0 - configuration.peekingCardScale) * min(distanceFromCenter, 1.0), 0.9))
                    
                    let baseOpacity = isCenterCard
                        ? 1.0
                        : max(1.0 - (1.0 - configuration.peekingCardOpacity) * min(distanceFromCenter, 1.0), 0.5)
                    let opacity = isFullscreen
                        ? (isCenterCard ? 1.0 : 0.0)
                        : baseOpacity
                    
                    cardView(
                        item: item,
                        isCenterCard: isCenterCard,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        screenSize: screenSize,
                        isFullscreen: isFullscreen
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .position(x: currentX, y: currentY)
                    .zIndex(isCenterCard ? 2 : 1)
                    .allowsHitTesting(isFullscreen ? isCenterCard : true)
                    .onTapGesture {
                        if !isCenterCard && !isFullscreen {
                            switchCard(to: index)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .simultaneousGesture(floatingDragGesture(step: step))
    }
    
    // MARK: - Single Card View
    
    @ViewBuilder
    private func cardView(
        item: Item,
        isCenterCard: Bool,
        cardWidth: CGFloat,
        cardHeight: CGFloat,
        screenSize: CGSize,
        isFullscreen: Bool
    ) -> some View {
        let currentWidth = isFullscreen ? screenSize.width : cardWidth
        let currentHeight = isFullscreen ? screenSize.height : cardHeight
        let currentCornerRadius = isFullscreen ? configuration.fullscreenCornerRadius : configuration.floatingCornerRadius
        let currentShadowOpacity = isFullscreen ? 0.0 : (isCenterCard ? 0.22 : 0.12)
        let currentShadowRadius: CGFloat = isFullscreen ? 0 : (isCenterCard ? 18 : 8)
        let currentShadowY: CGFloat = isFullscreen ? 0 : (isCenterCard ? 8 : 4)
        
        ZStack(alignment: .topLeading) {
            Color.white
            
            VStack(spacing: 0) {
                // Top Bounds / Safe Area Header Bar for Fullscreen mode (only when showDismissChevron is true)
                if isFullscreen && isCenterCard && configuration.showDismissChevron {
                    fullscreenTopHeader(screenSize: screenSize, topInset: safeAreaTopInset)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Card Detail Content
                Group {
                    if let unified = unifiedDetail {
                        unified(item, isFullscreen && isCenterCard) {
                            collapseToFloating()
                        }
                    } else if let floating = floatingCard, let fullscreen = fullscreenDetail {
                        if isCenterCard && isFullscreen {
                            fullscreen(item) {
                                collapseToFloating()
                            }
                        } else {
                            floating(item)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipped()
            
            // Top Dismiss Chevron inside the card when in floating mode (only on center card)
            if !isFullscreen && isCenterCard && configuration.showDismissChevron {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(white: 0.25))
                        .frame(width: 34, height: 34)
                        .background(Color(white: 0.93))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 12)
                .padding(.leading, 12)
                .transition(.opacity)
            }
        }
        .frame(width: currentWidth, height: currentHeight)
        .background(
            RoundedRectangle(
                cornerRadius: currentCornerRadius,
                style: .continuous
            )
            .fill(Color.white)
            .shadow(
                color: Color.black.opacity(currentShadowOpacity),
                radius: currentShadowRadius,
                x: 0,
                y: currentShadowY
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: currentCornerRadius,
                style: .continuous
            )
        )
    }
    
    // MARK: - Fullscreen Safe Area Header
    
    private var safeAreaTopInset: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
           window.safeAreaInsets.top > 0 {
            return window.safeAreaInsets.top
        }
        return 59
    }
    
    @ViewBuilder
    private func fullscreenTopHeader(screenSize: CGSize, topInset: CGFloat) -> some View {
        if !configuration.showDismissChevron {
            EmptyView()
        } else {
            fullscreenTopHeaderContent(screenSize: screenSize, topInset: topInset)
        }
    }
    
    @ViewBuilder
    private func fullscreenTopHeaderContent(screenSize: CGSize, topInset: CGFloat) -> some View {
        let headerHeight: CGFloat = 44
        
        ZStack(alignment: .leading) {
            Color.white
                .frame(maxWidth: .infinity)
                .frame(height: topInset + headerHeight)
            
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: topInset)
                
                HStack {
                    if configuration.showDismissChevron {
                        Button {
                            collapseToFloating()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(white: 0.25))
                                .frame(width: 36, height: 36)
                                .background(Color(white: 0.93))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, 16)
                    }
                    
                    Spacer()
                }
                .frame(height: headerHeight)
            }
        }
        .frame(height: topInset + headerHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    if value.translation.height > 0 && abs(value.translation.height) > abs(value.translation.width) {
                        fullscreenDragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > configuration.swipeDownThreshold || value.predictedEndTranslation.height > 120 {
                        fullscreenDragOffset = 0
                        collapseToFloating()
                    } else {
                        withAnimation(.spring(
                            response: configuration.animationResponse,
                            dampingFraction: configuration.animationDampingFraction
                        )) {
                            fullscreenDragOffset = 0
                        }
                    }
                }
        )
    }
    
    // MARK: - Gestures & Interactions
    
    private var interactiveVerticalOffset: CGFloat {
        if dragOffset.height < 0 {
            return 0 // Never drag up partially; as soon as swipe-up begins, it smoothly animates directly to fullscreen
        } else {
            return dragOffset.height
        }
    }
    
    private func floatingDragGesture(step: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard presentationState == .floatingCard else { return }
                
                let start = value.startLocation
                
                // Check if touch started inside an excluded child scroll rect (e.g. variant selector)
                let isInsideExcludedRect = excludedScrollRects.contains { rect in
                    rect.contains(start)
                }
                
                let translation = value.translation
                
                // Axis-lock to ensure horizontal drag does not jitter vertical, and vice-versa
                if lockedAxis == nil {
                    if abs(translation.height) > abs(translation.width) && abs(translation.height) > 6 {
                        lockedAxis = .vertical
                    } else if abs(translation.width) > abs(translation.height) && abs(translation.width) > 6 {
                        if isInsideExcludedRect {
                            // Touch started in variant scroll view - do NOT capture horizontal drag!
                            lockedAxis = .ignored
                        } else {
                            lockedAxis = .horizontal
                        }
                    }
                }
                
                if lockedAxis == .horizontal {
                    let translationX = translation.width
                    let isAtFirst = currentIndex == 0 && translationX > 0
                    let isAtLast = currentIndex >= items.count - 1 && translationX < 0
                    
                    if isAtFirst || isAtLast {
                        // iOS rubber-band resistance at list boundaries
                        let sign: CGFloat = translationX > 0 ? 1.0 : -1.0
                        let absTranslation = abs(translationX)
                        let rubberBanded = sign * (absTranslation * 0.35)
                        dragOffset = CGSize(width: rubberBanded, height: 0)
                    } else {
                        dragOffset = CGSize(width: translationX, height: 0)
                    }
                } else if lockedAxis == .vertical {
                    if translation.height < -18 {
                        // Swipe UP: Immediately expand to fullscreen without double movement
                        lockedAxis = .ignored
                        expandToFullscreen()
                    } else if translation.height >= 0 {
                        // Swipe DOWN: Interactive drag-to-dismiss
                        dragOffset = CGSize(width: 0, height: translation.height)
                    }
                }
            }
            .onEnded { value in
                guard presentationState == .floatingCard else { return }
                
                let axis = lockedAxis
                lockedAxis = nil
                
                if axis == .vertical {
                    let translation = value.translation.height
                    let velocity = value.predictedEndTranslation.height - translation
                    if translation < -18 || velocity < -80 {
                        expandToFullscreen()
                    } else if translation > configuration.swipeDownThreshold || velocity > 100 {
                        dismiss(fromDrag: true)
                    } else {
                        withAnimation(.spring(
                            response: configuration.animationResponse,
                            dampingFraction: configuration.animationDampingFraction
                        )) {
                            dragOffset = .zero
                        }
                    }
                } else if axis == .horizontal {
                    let translation = value.translation.width
                    let velocity = value.predictedEndTranslation.width - translation
                    let threshold = step * 0.18
                    
                    var targetIndex = currentIndex
                    if (translation < -threshold || velocity < -120) && currentIndex < items.count - 1 {
                        targetIndex = currentIndex + 1
                    } else if (translation > threshold || velocity > 120) && currentIndex > 0 {
                        targetIndex = currentIndex - 1
                    }
                    
                    switchCard(to: targetIndex)
                } else {
                    withAnimation(.spring(
                        response: configuration.animationResponse,
                        dampingFraction: configuration.animationDampingFraction
                    )) {
                        dragOffset = .zero
                    }
                }
            }
    }
    
    // MARK: - State Transitions & Card Switching
    
    private func switchCard(to targetIndex: Int) {
        guard items.indices.contains(targetIndex) else {
            withAnimation(.spring(
                response: configuration.animationResponse,
                dampingFraction: configuration.animationDampingFraction
            )) {
                dragOffset = .zero
            }
            return
        }
        
        let newItem = items[targetIndex]
        withAnimation(.spring(
            response: configuration.animationResponse,
            dampingFraction: configuration.animationDampingFraction
        )) {
            selectedItem = newItem
            dragOffset = .zero
        }
        
        handleItemActivated(newItem, at: targetIndex)
    }
    
    private func expandToFullscreen() {
        dragOffset = .zero
        withAnimation(.spring(
            response: configuration.animationResponse,
            dampingFraction: configuration.animationDampingFraction
        )) {
            presentationState = .fullscreen
        }
    }
    
    private func collapseToFloating() {
        dragOffset = .zero
        withAnimation(.spring(
            response: configuration.animationResponse,
            dampingFraction: configuration.animationDampingFraction
        )) {
            fullscreenDragOffset = 0
            presentationState = .floatingCard
        }
    }
    
    private func dismiss(fromDrag: Bool = false) {
        if fromDrag {
            withAnimation(.spring(
                response: configuration.animationResponse,
                dampingFraction: configuration.animationDampingFraction
            )) {
                dragOffset = CGSize(width: 0, height: 1000)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let onDismissRequested {
                    onDismissRequested()
                } else {
                    presentationState = .dismissed
                    selectedItem = nil
                }
            }
        } else {
            dragOffset = .zero
            if let onDismissRequested {
                onDismissRequested()
            } else {
                withAnimation(.spring(
                    response: configuration.animationResponse,
                    dampingFraction: configuration.animationDampingFraction
                )) {
                    presentationState = .dismissed
                    selectedItem = nil
                }
            }
        }
    }
    
    private func handleItemActivated(_ item: Item, at index: Int) {
        if lastNotifiedItemId != item.id {
            lastNotifiedItemId = item.id
            onCardFocused?(item)
        }
        
        if index >= items.count - configuration.loadMoreThreshold {
            onLoadMore?()
        }
    }
}
