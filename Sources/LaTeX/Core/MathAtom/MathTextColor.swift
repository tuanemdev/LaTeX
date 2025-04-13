//
//  File.swift
//  LaTeX
//
//  Created by Nguyen Tuan Anh on 12/4/25.
//

import Foundation
// MARK: - MTMathTextColor
/** An atom representing an textcolor element.
 Note: None of the usual fields of the `MathAtom` apply even though this
 class inherits from `MathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
public class MathTextColor: MathAtom {
    public var colorString:String=""
    public var innerList:MathAtomList?
    
    override init() {
        super.init()
        self.type = .textcolor
    }
    
    override public var finalized: MathAtom {
        let newColor = super.finalized as! MathTextColor
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathTextColor()
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
        "\\textcolor{\(self.colorString)}{\(self.innerList!.description)}"
    }
}
