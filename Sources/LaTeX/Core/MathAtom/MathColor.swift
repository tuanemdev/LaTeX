import Foundation

public class MathColor: MathAtom {
    public var colorString: String = ""
    public var innerList: MathAtomList?
    
    override public var finalized: MathAtom {
        let newColor = super.finalized as! MathColor
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathColor()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms
        copy.colorString = self.colorString
        copy.innerList = self.innerList?.deepCopy()
        return copy
    }
    
    override public var description: String {
        "\\color{\(self.colorString)}{\(self.innerList!.description)}"
    }
}
