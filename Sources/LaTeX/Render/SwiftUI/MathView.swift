import SwiftUI

public struct MathView: UIViewRepresentable {
    let latex: String
    var mathFont: MathFont? = MathFontType.defaultMathFont
    var mathFontSize: CGFloat = 20
    var textColor: LaTeXColor = LaTeXColor.black
    var contentInsets: LaTeXEdgeInsets = zeroInsets
    var labelMode: MathLabel.MathMode = .display
    var textAlignment: MathLabel.MathAlignment = .left
    
    public init(latex: String) {
        self.latex = latex
    }
    
    public func makeUIView(context: Context) -> MathLabel {
        let mathLabel = MathLabel()
        mathLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        mathLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return mathLabel
    }
    
    public func updateUIView(_ uiView: MathLabel, context: Context) {
        uiView.latex = latex
    }
}

// MARK: - MathView Modifiers
public extension MathView {
}
