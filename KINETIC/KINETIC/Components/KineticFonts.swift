import SwiftUI

extension Font {
    static func inter(_ size: CGFloat, weight: InterWeight = .regular) -> Font {
        .custom(weight.fontName, size: size)
    }

    enum InterWeight: String {
        case regular   = "Inter-Regular"
        case medium    = "Inter-Medium"
        case semibold  = "Inter-SemiBold"
        case bold      = "Inter-Bold"
        case extraBold = "Inter-ExtraBold"
        case black     = "Inter-Black"

        var fontName: String { rawValue }
    }
}
