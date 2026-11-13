#if canImport(CoreText) && canImport(Foundation)
import CoreText
import Foundation

public enum FontRegistration {
    public static func register(bundle: Bundle) {
        let names = [
            "BarlowCondensed-Bold",
            "BarlowCondensed-ExtraBold",
            "BarlowCondensed-Black"
        ]
        for name in names {
            let url = bundle.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? bundle.url(forResource: name, withExtension: "ttf")
            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
#endif
