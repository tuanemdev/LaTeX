import Foundation

public class MathSpace: MathAtom {
    /** The amount of space represented by this object in mu units. */
    public var space: CGFloat = 0
    
    init(space: CGFloat) {
        super.init()
        self.type = .space
        self.space = space
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathSpace(space: self.space)
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms
        copy.space = self.space
        return copy
    }
}
