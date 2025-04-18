import SwiftUI

public struct MathView: UIViewRepresentable {
    var latex: String
    
    public init(latex: String) {
        self.latex = latex
    }
    
    public func makeUIView(context: Context) -> MathLabel {
        let mathLabel = MathLabel()
        mathLabel.labelMode = .display
        mathLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        mathLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return mathLabel
    }
    
    public func updateUIView(_ uiView: MathLabel, context: Context) {
        uiView.latex = latex
    }
}
