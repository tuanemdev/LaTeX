import Foundation

public class MathRadical: MathAtom {
    /// Denotes the term under the square root sign
    public var radicand: MathAtomList?
    
    /// Denotes the degree of the radical, i.e. the value to the top left of the radical sign
    /// This can be null if there is no degree.
    public var degree: MathAtomList?
    
    override init() {
        super.init()
        self.type = .radical
        self.nucleus = ""
    }
    
    override public var finalized: MathAtom {
        let newRad = super.finalized as! MathRadical
        newRad.radicand = newRad.radicand?.finalized
        newRad.degree = newRad.degree?.finalized
        return newRad
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathRadical()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms
        copy.radicand = self.radicand?.deepCopy()
        copy.degree = self.degree?.deepCopy()
        return copy
    }
    
    override public var description: String {
        var string = "\\sqrt"
        if self.degree != nil {
            string += "[\(self.degree!.description)]"
        }
        if self.radicand != nil {
            string += "{\(self.radicand?.description ?? "placeholder")}"
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
