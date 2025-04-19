import Foundation

public enum LineStyle: Int {
    /// Display style
    case display
    /// Text style (inline)
    case text
    /// Script style (for sub/super scripts)
    case script
    /// Script script style (for scripts of scripts)
    case scriptOfScript
    
    public func inc() -> LineStyle {
        let raw = self.rawValue + 1
        if let style = LineStyle(rawValue: raw) { return style }
        return .display
    }
    
    public var isNotScript: Bool {
        self < .script
    }
}

extension LineStyle: Comparable {
    public static func < (lhs: LineStyle, rhs: LineStyle) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension LineStyle: Sendable { }

// MARK: - MTMathStyle
public class MathStyle: MathAtom {
    public var style: LineStyle = .display
    
    init(style: LineStyle) {
        super.init()
        self.type = .style
        self.style = style
    }
    
    override init() {
        super.init()
        self.type = .style
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathStyle()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms
        copy.style = self.style
        return copy
    }
}
