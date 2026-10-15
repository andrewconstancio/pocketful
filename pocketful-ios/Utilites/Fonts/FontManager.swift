import SwiftUI

/// A helper method for this apps fonts.
struct FontManager {
    /// CormorantGaramond fonts.
    enum CormorantGaramond: String {
        /// Regular.
        case regular = "CormorantGaramond-Regular"
        
        /// The SwiftUI font for this CormorantGaramond weight, at `size`.
        func font(size: CGFloat) -> Font {
            return .custom(self.rawValue, size: size)
        }
    }
}
