import Foundation

public class MTFontManager {
    
    static nonisolated(unsafe) public private(set) var manager: MTFontManager = {
        MTFontManager()
    }()
    
    let kDefaultFontSize = CGFloat(20)
    
    static var fontManager : MTFontManager {
        return manager
    }

    public init() { }

    var nameToFontMap = [String: MTFont]()

    public func font(withName name:String, size:CGFloat) -> MTFont? {
        var f = self.nameToFontMap[name]
        if f == nil {
            f = MTFont(fontWithName: name, size: size)
            self.nameToFontMap[name] = f
        }
        
        if f!.fontSize == size { return f }
        else { return f!.copy(withSize: size) }
    }
    
    public func latinModernFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "latinmodern-math", size: size)
    }
    
    public func kpMathLightFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "KpMath-Light", size: size)
    }
    
    public func kpMathSansFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "KpMath-Sans", size: size)
    }
    
    public func xitsFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "xits-math", size: size)
    }
    
    public func termesFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "texgyretermes-math", size: size)
    }
    
    public func asanaFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "Asana-Math", size: size)
    }
    
    public func eulerFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "Euler-Math", size: size)
    }
    
    public func firaRegularFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "FiraMath-Regular", size: size)
    }
    
    public func notoSansRegularFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "NotoSansMath-Regular", size: size)
    }
    
    public func libertinusRegularFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "LibertinusMath-Regular", size: size)
    }
    
    public func garamondMathFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "Garamond-Math", size: size)
    }
    
    public func leteSansFont(withSize size:CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: "LeteSansMath", size: size)
    }
    
    public var defaultFont: MTFont? {
        MTFontManager.fontManager.latinModernFont(withSize: kDefaultFontSize)
    }


}
