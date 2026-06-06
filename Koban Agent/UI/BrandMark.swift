import SwiftUI

/// The Koban shield mark, rendered from the template vector asset at a fixed square size. It is a
/// template image, so the caller's `.foregroundStyle` tints it. This is the single definition of
/// the brand glyph in SwiftUI; the menu-bar status item draws the same asset through AppKit.
struct BrandMark: View {
    let size: CGFloat

    var body: some View {
        Image(ImageAssets.brandMark)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
