#if canImport(UIKit)
import UIKit

public typealias LaTeXView          = UIView
public typealias LaTeXColor         = UIColor
public typealias LaTeXBezierPath    = UIBezierPath
public typealias LaTeXLabel         = UILabel
public typealias LaTeXEdgeInsets    = UIEdgeInsets
public typealias LaTeXRect          = CGRect
public typealias LaTeXImage         = UIImage

var zeroInsets:                     UIEdgeInsets { UIEdgeInsets.zero }
var currentContext:                 CGContext? { UIGraphicsGetCurrentContext() }
#endif

#if canImport(AppKit)
import AppKit

public typealias LaTeXView          = NSView
public typealias LaTeXColor         = NSColor
public typealias LaTeXBezierPath    = NSBezierPath
public typealias LaTeXEdgeInsets    = NSEdgeInsets
public typealias LaTeXRect          = NSRect
public typealias LaTeXImage         = NSImage

var zeroInsets:                     NSEdgeInsets { .init(top: 0, left: 0, bottom: 0, right: 0) }
var currentContext:                 CGContext? { NSGraphicsContext.current?.cgContext }
#endif
