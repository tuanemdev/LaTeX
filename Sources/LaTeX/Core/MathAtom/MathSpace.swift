import Foundation

public class MathSpace: MathAtom {
    /** The amount of space represented by this object in mu units. */
    public var space: CGFloat = 0
    
    init(space:CGFloat) {
        super.init()
        self.type = .space
        self.space = space
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! MathSpace
        copy.space = self.space
        return copy
    }
}
