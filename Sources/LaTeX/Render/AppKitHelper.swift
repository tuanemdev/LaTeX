#if canImport(AppKit)
import AppKit

extension LaTeXBezierPath {
    func addLine(to point: CGPoint) {
        self.line(to: point)
    }
}

extension LaTeXView {
    var backgroundColor: LaTeXColor? {
        get {
            LaTeXColor(cgColor: self.layer?.backgroundColor ?? LaTeXColor.clear.cgColor)
        }
        set {
            self.layer?.backgroundColor = LaTeXColor.clear.cgColor
            self.wantsLayer = true
        }
    }
}

public class LaTeXLabel: NSTextField {
    init() {
        super.init(frame: .zero)
        self.stringValue = ""
        self.isBezeled = false
        self.drawsBackground = false
        self.isEditable = false
        self.isSelectable = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    var text: String? {
        get { super.stringValue }
        set { super.stringValue = newValue! }
    }
}
#endif
