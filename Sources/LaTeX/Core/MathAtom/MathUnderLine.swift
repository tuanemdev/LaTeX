import Foundation

public class MathUnderLine: MathAtom {
    public var innerList:  MathAtomList?
    
    override public var finalized: MathAtom {
        let newUnderline = super.finalized as! MathUnderLine
        newUnderline.innerList = newUnderline.innerList?.finalized
        return newUnderline
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! MathUnderLine
        copy.innerList = self.innerList?.deepCopy()
        return copy
    }
    
    override init() {
        super.init()
        self.type = .underline
    }
}
