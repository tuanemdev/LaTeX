import Foundation

public class MathLargeOperator: MathAtom {
    public var limits: Bool = false
    
    init(value: String, limits: Bool) {
        super.init(type: .largeOperator, value: value)
        self.limits = limits
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathLargeOperator(value: self.nucleus, limits: self.limits)
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms
        copy.limits = self.limits
        return copy
    }
}
