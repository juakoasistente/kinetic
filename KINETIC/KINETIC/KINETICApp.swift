//
//  KINETICApp.swift
//  KINETIC
//
//  Created by joaquin on 2/4/26.
//

import SwiftUI
import CoreText

@main
struct KINETICApp: App {

    init() {
        Self.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }

    private static func registerFonts() {
        let fonts = [
            "Inter-Regular",
            "Inter-Medium",
            "Inter-SemiBold",
            "Inter-Bold",
            "Inter-ExtraBold",
            "Inter-Black"
        ]
        for font in fonts {
            guard let url = Bundle.main.url(forResource: font, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
