import Foundation

public class MathAccent: MathAtom {
    public var innerList:  MathAtomList?
    
    init(value: String) {
        super.init()
        self.type = .accent
        self.nucleus = value
    }
    
    override public var finalized: MathAtom {
        let newAccent = super.finalized as! MathAccent
        newAccent.innerList = newAccent.innerList?.finalized
        return newAccent
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! MathAccent
        copy.innerList = self.innerList?.deepCopy()
        return copy
    }
}
