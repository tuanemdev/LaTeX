import Foundation

// MARK: - MathOverLine
/** An atom with a line over the contained math list. */
public class MathOverLine: MathAtom {
    public var innerList:  MathAtomList?
    
    override init() {
        super.init()
        self.type = .overline
    }
    
    override public var finalized: MathAtom {
        let newOverline = super.finalized as! MathOverLine
        newOverline.innerList = newOverline.innerList?.finalized
        return newOverline
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathOverLine()
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
}
