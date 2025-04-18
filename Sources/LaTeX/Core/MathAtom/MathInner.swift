import Foundation

public class MathInner: MathAtom {
    /// The inner math list
    public var innerList: MathAtomList?
    
    /// The left boundary atom. This must be a node of type kMathAtomBoundary
    public var leftBoundary: MathAtom? {
        didSet {
            if leftBoundary?.type != .boundary {
                fatalError("Left boundary must be of type .boundary")
            }
        }
    }
    
    /// The right boundary atom. This must be a node of type kMathAtomBoundary
    public var rightBoundary: MathAtom? {
        didSet {
            if rightBoundary?.type != .boundary {
                fatalError("Right boundary must be of type .boundary")
            }
        }
    }
    
    override init() {
        super.init()
        self.type = .inner
    }
    
    override public var finalized: MathAtom {
        let newInner = super.finalized as! MathInner
        newInner.innerList = newInner.innerList?.finalized
        return newInner
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathInner()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms.map { $0.deepCopy() }
        copy.innerList = self.innerList?.deepCopy()
        copy.leftBoundary = self.leftBoundary?.deepCopy()
        copy.rightBoundary = self.rightBoundary?.deepCopy()
        return copy
    }
    
    override public var description: String {
        var string = "\\inner"
        if self.leftBoundary != nil {
            string += "[\(self.leftBoundary!.nucleus)]"
        }
        string += "{\(self.innerList!.description)}"
        if self.rightBoundary != nil {
            string += "[\(self.rightBoundary!.nucleus)]"
        }
        if self.superScript != nil {
            string += "^{\(self.superScript!.description)}"
        }
        if self.subScript != nil {
            string += "_{\(self.subScript!.description)}"
        }
        return string
    }
}
