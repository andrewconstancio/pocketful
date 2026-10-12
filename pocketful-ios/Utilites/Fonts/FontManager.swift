import SwiftUI

/// A helper method for this apps fonts.
struct FontManager {
    /// Nunito fonts.
    enum CormorantGaramond: String {
        /// Regular.
        case regular = "CormorantGaramond"
        
//        /// Bold.
//        case bold = "Nunito-Bold"
//        
//        /// Extra bold.
//        case extraBold = "Nunito-ExtraBold"
        
        /// The SwiftUI font for this Nunito weight, at `size`.
        func font(size: CGFloat) -> Font {
            return .custom(self.rawValue, size: size)
        }
    }
}
