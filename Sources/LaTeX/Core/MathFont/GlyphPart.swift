import Foundation
import CoreText

struct GlyphPart {
    /// The glyph that represents this part
    var glyph: CGGlyph!
    
    /// Full advance width/height for this part, in the direction of the extension in points.
    var fullAdvance: CGFloat = 0
    
    /// Advance width/ height of the straight bar connector material at the beginning of the glyph in points.
    var startConnectorLength: CGFloat = 0
    
    /// Advance width/ height of the straight bar connector material at the end of the glyph in points.
    var endConnectorLength: CGFloat = 0
    
    /// If this part is an extender. If set, the part can be skipped or repeated.
    var isExtender: Bool = false
}
