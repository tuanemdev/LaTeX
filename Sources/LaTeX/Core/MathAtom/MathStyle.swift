//
//  File.swift
//  LaTeX
//
//  Created by Nguyen Tuan Anh on 12/4/25.
//

import Foundation
/**
 Styling of a line of math
 */
public enum LineStyle: Int, Comparable {
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
    
    public var isNotScript:Bool { self < .script }
    public static func < (lhs: LineStyle, rhs: LineStyle) -> Bool { lhs.rawValue < rhs.rawValue }
}

// MARK: - MTMathStyle
public class MathStyle: MathAtom {
    public var style: LineStyle = .display
    
    init(style:LineStyle) {
        super.init()
        self.type = .style
        self.style = style
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! MathStyle
        copy.style = self.style
        return copy
    }
}
