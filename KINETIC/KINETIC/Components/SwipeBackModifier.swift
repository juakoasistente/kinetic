import SwiftUI

struct SwipeBackModifier: ViewModifier {
    var action: () -> Void

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = abs(value.translation.height)
                        if horizontal > 60 && vertical < horizontal {
                            action()
                        }
                    }
            )
    }
}

extension View {
    func swipeBack(action: @escaping () -> Void) -> some View {
        modifier(SwipeBackModifier(action: action))
    }
}
