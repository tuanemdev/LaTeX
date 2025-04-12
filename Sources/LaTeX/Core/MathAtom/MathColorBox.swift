import Foundation

public class MathColorBox: MathAtom {
    public var colorString = ""
    public var innerList: MathAtomList?
    
    override public var finalized: MathAtom {
        let newColor = super.finalized as! MathColorBox
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
    
    override public var description: String {
        "\\colorbox{\(self.colorString)}{\(self.innerList!.description)}"
    }
}
