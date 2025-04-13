import Foundation

public class MathUnderLine: MathAtom {
    public var innerList:  MathAtomList?
    
    override public var finalized: MathAtom {
        let newUnderline = super.finalized as! MathUnderLine
        newUnderline.innerList = newUnderline.innerList?.finalized
        return newUnderline
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathUnderLine()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms
        copy.innerList = self.innerList?.deepCopy()
        return copy
    }
    
    override init() {
        super.init()
        self.type = .underline
    }
}
