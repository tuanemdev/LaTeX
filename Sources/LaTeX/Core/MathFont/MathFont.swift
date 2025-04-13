import Foundation
import CoreText

public struct MathFont {
    let cgFont: CGFont
    let ctFont: CTFont
    var fontTable: MathFontTable?
    
    init(name: String, size: CGFloat) {
        let fontPath = Bundle.module.path(forResource: name, ofType: "otf")!
        let fontDataProvider: CGDataProvider = .init(filename: fontPath)!
        self.cgFont = CGFont(fontDataProvider)!
        self.ctFont = CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
        let mathTablePlist = Bundle.module.url(forResource:name, withExtension: "plist")
        self.fontTable = MathFontTable(withFont: self, mathTable: NSDictionary(contentsOf: mathTablePlist!)!)
    }
    
    init(_ other: MathFont, withSize size: CGFloat) {
        self.cgFont = other.cgFont
        self.ctFont = CTFontCreateWithGraphicsFont(other.cgFont, size, nil, nil)
        self.fontTable = other.fontTable
    }
    
    func getName(for glyph: CGGlyph) -> String {
        let name = cgFont.name(for: glyph) as? String
        return name ?? ""
    }
    
    func getGlyph(with name: String) -> CGGlyph {
        cgFont.getGlyphWithGlyphName(name: name as CFString)
    }
    
    var fontSize: CGFloat {
        CTFontGetSize(ctFont)
    }
    
    /// Tạo font mới tương ứng với kích thước size khác
    func copy(withSize size: CGFloat) -> MathFont {
        MathFont(self, withSize: size)
    }
}
