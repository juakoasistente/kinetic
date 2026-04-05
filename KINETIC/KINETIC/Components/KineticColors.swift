import SwiftUI

extension Color {
    // MARK: - Primary
    static let stravaOrange = Color(hex: 0xFC5200)  // #FC5200 - O50
    static let kineticBlack = Color(hex: 0x000000)  // #000000
    static let kineticWhite = Color(hex: 0xFFFFFF)  // #FFFFFF

    // MARK: - Orange variants
    static let pumpkin = Color(hex: 0xFC6100)  // #FC6100 - O40
    static let rust    = Color(hex: 0xCC4200)  // #CC4200 - O60

    // MARK: - Danger
    static let danger  = Color(hex: 0xBA1A1A)  // #BA1A1A

    // MARK: - Neutrals
    static let coal    = Color(hex: 0x242428)  // #242428 - N90
    static let asphalt = Color(hex: 0x494950)  // #494950 - N80
    static let gravel  = Color(hex: 0x6D6D78)  // #6D6D78 - N70
    static let silver  = Color(hex: 0xDFDFE8)  // #DFDFE8 - N30
    static let mist    = Color(hex: 0xF3F3F6)  // #F3F3F6 - N15
    static let icicle  = Color(hex: 0xF0F0F5)  // #F0F0F5 - N20
    static let fog     = Color(hex: 0xF7F7FA)  // #F7F7FA - N10
}

extension ShapeStyle where Self == Color {
    // MARK: - Primary
    static var stravaOrange: Color { Color(hex: 0xFC5200) }  // #FC5200
    static var kineticBlack: Color { Color(hex: 0x000000) }  // #000000
    static var kineticWhite: Color { Color(hex: 0xFFFFFF) }  // #FFFFFF

    // MARK: - Orange variants
    static var pumpkin: Color { Color(hex: 0xFC6100) }  // #FC6100
    static var rust: Color    { Color(hex: 0xCC4200) }  // #CC4200

    // MARK: - Danger
    static var danger: Color  { Color(hex: 0xBA1A1A) }  // #BA1A1A

    // MARK: - Neutrals
    static var coal: Color    { Color(hex: 0x242428) }  // #242428
    static var asphalt: Color { Color(hex: 0x494950) }  // #494950
    static var gravel: Color  { Color(hex: 0x6D6D78) }  // #6D6D78
    static var silver: Color  { Color(hex: 0xDFDFE8) }  // #DFDFE8
    static var mist: Color    { Color(hex: 0xF3F3F6) }  // #F3F3F6
    static var icicle: Color  { Color(hex: 0xF0F0F5) }  // #F0F0F5
    static var fog: Color     { Color(hex: 0xF7F7FA) }  // #F7F7FA
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
