import SwiftUI

public struct MathView: UIViewRepresentable {
    var latex: String
    
    public init(latex: String) {
        self.latex = latex
    }
    
    public func makeUIView(context: Context) -> MathLabel {
        let mathLabel = MathLabel()
        mathLabel.labelMode = .display
        return mathLabel
    }
    
    public func updateUIView(_ uiView: MathLabel, context: Context) {
        uiView.latex = latex
    }
}
