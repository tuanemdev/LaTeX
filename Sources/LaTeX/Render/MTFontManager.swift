import Foundation

public class MathFontManager {
    
    static nonisolated(unsafe) public private(set) var manager: MathFontManager = {
        MathFontManager()
    }()
    
    let kDefaultFontSize = CGFloat(20)
    
    static var fontManager : MathFontManager {
        return manager
    }

    public init() { }

    var nameToFontMap = [String: MathFont]()

    public func font(withName name:String, size:CGFloat) -> MathFont? {
        var f = self.nameToFontMap[name]
        if f == nil {
            f = MathFont(fontWithName: name, size: size)
            self.nameToFontMap[name] = f
        }
        
        if f!.fontSize == size { return f }
        else { return f!.copy(withSize: size) }
    }
    
    public func latinModernFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "latinmodern-math", size: size)
    }
    
    public func kpMathLightFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "KpMath-Light", size: size)
    }
    
    public func kpMathSansFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "KpMath-Sans", size: size)
    }
    
    public func xitsFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "xits-math", size: size)
    }
    
    public func termesFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "texgyretermes-math", size: size)
    }
    
    public func asanaFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "Asana-Math", size: size)
    }
    
    public func eulerFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "Euler-Math", size: size)
    }
    
    public func firaRegularFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "FiraMath-Regular", size: size)
    }
    
    public func notoSansRegularFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "NotoSansMath-Regular", size: size)
    }
    
    public func libertinusRegularFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "LibertinusMath-Regular", size: size)
    }
    
    public func garamondMathFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "Garamond-Math", size: size)
    }
    
    public func leteSansFont(withSize size:CGFloat) -> MathFont? {
        MathFontManager.fontManager.font(withName: "LeteSansMath", size: size)
    }
    
    public var defaultFont: MathFont? {
        MathFontManager.fontManager.latinModernFont(withSize: kDefaultFontSize)
    }


}
