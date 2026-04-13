import SwiftUI

extension View {
    /// Dismiss keyboard when tapping outside of text fields
    func dismissKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }

    /// Dismiss keyboard when scrolling
    func dismissKeyboardOnScroll() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }
}

