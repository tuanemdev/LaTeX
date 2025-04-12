import Foundation

public enum MathAtomType: Int {
    /// A number or text in ordinary format - Ord in TeX
    case ordinary = 1
    /// A number - Does not exist in TeX
    case number
    /// A variable (i.e. text in italic format) - Does not exist in TeX
    case variable
    /// A large operator such as (sin/cos, integral etc.) - Op in TeX
    case largeOperator
    /// A binary operator - Bin in TeX
    case binaryOperator
    /// A unary operator - Does not exist in TeX.
    case unaryOperator
    /// A relation, e.g. = > < etc. - Rel in TeX
    case relation
    /// Open brackets - Open in TeX
    case open
    /// Close brackets - Close in TeX
    case close
    /// A fraction e.g 1/2 - generalized fraction node in TeX
    case fraction
    /// A radical operator e.g. sqrt(2)
    case radical
    /// Punctuation such as , - Punct in TeX
    case punctuation
    /// A placeholder square for future input. Does not exist in TeX
    case placeholder
    /// An inner atom, i.e. an embedded math list - Inner in TeX
    case inner
    /// An underlined atom - Under in TeX
    case underline
    /// An overlined atom - Over in TeX
    case overline
    /// An accented atom - Accent in TeX
    case accent
    
    /// A left atom - Left & Right in TeX. We don't need two since we track boundaries separately.
    case boundary = 101
    
    /// Spacing between math atoms. This denotes both glue and kern for TeX. We do not
    /// distinguish between glue and kern.
    case space = 201
    
    /// Denotes style changes during rendering.
    case style
    case color
    case textcolor
    case colorBox
    
    /// An table atom. This atom does not exist in TeX. It is equivalent to the TeX command
    /// halign which is handled outside of the TeX math rendering engine. We bring it into our
    /// math typesetting to handle matrices and other tables.
    case table = 1001
}

// MARK: - Computed Properties
extension MathAtomType {
    var isNotBinaryOperator: Bool {
        switch self {
        case .binaryOperator, .relation, .open, .punctuation, .largeOperator:
            true
        default:
            false
        }
    }
    
    var isScriptAllowed: Bool {
        self < .boundary
    }
}

// MARK: - Comparable
extension MathAtomType: Comparable {
    public static func < (lhs: MathAtomType, rhs: MathAtomType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CustomStringConvertible
extension MathAtomType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ordinary:         "Ordinary"
        case .number:           "Number"
        case .variable:         "Variable"
        case .largeOperator:    "Large Operator"
        case .binaryOperator:   "Binary Operator"
        case .unaryOperator:    "Unary Operator"
        case .relation:         "Relation"
        case .open:             "Open"
        case .close:            "Close"
        case .fraction:         "Fraction"
        case .radical:          "Radical"
        case .punctuation:      "Punctuation"
        case .placeholder:      "Placeholder"
        case .inner:            "Inner"
        case .underline:        "Underline"
        case .overline:         "Overline"
        case .accent:           "Accent"
        case .boundary:         "Boundary"
        case .space:            "Space"
        case .style:            "Style"
        case .color:            "Color"
        case .textcolor:        "TextColor"
        case .colorBox:         "Colorbox"
        case .table:            "Table"
        }
    }
}
