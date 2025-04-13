import Foundation

public class MathAccent: MathAtom {
    public var innerList:  MathAtomList?
    
    override init() {
        super.init()
        self.type = .accent
    }
    
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
        let copy = MathAccent()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = MathAtomList(self.subScript)
        copy.superScript = MathAtomList(self.superScript)
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms
        copy.innerList = self.innerList?.deepCopy()
        return copy
    }
}
