import Foundation

public class MathFraction: MathAtom {
    public var hasRule: Bool = true
    public var leftDelimiter = ""
    public var rightDelimiter = ""
    public var numerator: MathAtomList?
    public var denominator: MathAtomList?
    
    init(hasRule rule: Bool = true) {
        super.init()
        self.type = .fraction
        self.hasRule = rule
    }
    
    override public var finalized: MathAtom {
        let newFrac = super.finalized as! MathFraction
        newFrac.numerator = newFrac.numerator?.finalized
        newFrac.denominator = newFrac.denominator?.finalized
        return newFrac
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathFraction()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms.map { $0.deepCopy() }
        copy.leftDelimiter = self.leftDelimiter
        copy.rightDelimiter = self.rightDelimiter
        copy.numerator = self.numerator?.deepCopy()
        copy.denominator = self.denominator?.deepCopy()
        return copy
    }
    
    override public var description: String {
        var string = self.hasRule ? "\\frac" : "\\atop"
        if !leftDelimiter.isEmpty {
            string += "[\(leftDelimiter)]"
        }
        if !rightDelimiter.isEmpty {
            string += "[\(rightDelimiter)]"
        }
        string += "{\(numerator?.description ?? "placeholder")}{\(denominator?.description ?? "placeholder")}"
        if superScript != nil {
            string += "^{\(superScript!.description)}"
        }
        if subScript != nil {
            string += "_{\(subScript!.description)}"
        }
        return string
    }
}
