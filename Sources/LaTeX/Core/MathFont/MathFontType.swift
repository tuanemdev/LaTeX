import Foundation

// MARK: - MathFontType
public enum MathFontType: String {
    case latinModern    = "latinmodern-math"
    case kpLight        = "KpMath-Light"
    case kpSans         = "KpMath-Sans"
    case xits           = "xits-math"
    case termes         = "texgyretermes-math"
    case asana          = "Asana-Math"
    case euler          = "Euler-Math"
    case fira           = "FiraMath-Regular"
    case notoSans       = "NotoSansMath-Regular"
    case libertinus     = "LibertinusMath-Regular"
    case garamond       = "Garamond-Math"
    case leteSans       = "LeteSansMath"
    
    func mathFont(withSize size: CGFloat) -> MathFont {
        return MathFont(name: self.rawValue, size: size)
    }
    
    static var defaultMathFont: MathFont {
        return MathFontType.latinModern.mathFont(withSize: 20.0)
    }
}
