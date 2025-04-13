import Foundation
import QuartzCore
import CoreText

// MARK: - MathAtomDisplay
class MathAtomDisplay {
    /// Khoảng cách từ trục đến đỉnh của vùng hiển thị
    var ascent: CGFloat = 0
    /// Khoảng cách từ trục đến đáy của vùng hiển thị
    var descent: CGFloat = 0
    /// Chiều rộng của vùng hiển thị
    var width: CGFloat = 0
    /// Vị trí của vùng hiển thị so với vùng hiển thị cha.
    var position: CGPoint = .zero
    /// Khoảng cách ký tự trong vùng hiển thị
    var range: NSRange = NSMakeRange(0, 0)
    /// Có chứa subscript/superscript hay không
    var hasScript: Bool = false
    /// Màu chữ
    var textColor: LaTeXColor?
    /// Màu chữ cục bộ
    var localTextColor: LaTeXColor?
    /// Màu nền
    var localBackgroundColor: LaTeXColor?
    /// Hạ thấp xuống một khoảng để hỗ trợ hiển thị Glyph
    var shiftDown: CGFloat = 0
    
    /// Vẽ trên graphics context.
    public func draw(_ context: CGContext) {
        guard let localBackgroundColor else { return }
        context.saveGState()
        context.setBlendMode(.normal)
        context.setFillColor(localBackgroundColor.cgColor)
        context.fill(self.displayBounds())
        context.restoreGState()
    }
    
    func displayBounds() -> CGRect {
        CGRectMake(
            position.x,
            position.y - descent,
            width,
            ascent + descent
        )
    }
}

// MARK: - MathCTLineDisplay
final class MathCTLineDisplay: MathAtomDisplay {
    
    /// The CTLine being displayed
    public var line: CTLine
    
    /// Dùng để tạo CTLineRef. Lưu ý rằng việc thiết lập này không đặt lại kích thước của vùng hiển thị
    private var attributedString: NSAttributedString {
        didSet {
            line = CTLineCreateWithAttributedString(attributedString)
        }
    }
    
    /// Mảng các toán tử toán học mà dòng CTLine này hiển thị. Được sử dụng để lập chỉ mục cho MathAtomList
    private(set) var atoms = [MathAtom]()
    
    init(
        withString attrString: NSAttributedString,
        position: CGPoint,
        range: NSRange,
        font: MathFont?,
        atoms: [MathAtom],
    ) {
        self.attributedString = attrString
        self.line = CTLineCreateWithAttributedString(attrString)
        super.init()
        self.position = position
        self.range = range
        self.atoms = atoms
        self.width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        self.ascent = max(0, CGRectGetMaxY(bounds) - 0)
        self.descent = max(0, 0 - CGRectGetMinY(bounds))
    }
    
    override var textColor: LaTeXColor? {
        didSet {
            let attrStr = attributedString.mutableCopy() as! NSMutableAttributedString
            attrStr.addAttribute(
                NSAttributedString.Key(kCTForegroundColorAttributeName as String),
                value: textColor?.cgColor ?? LaTeXColor.black.cgColor,
                range:NSMakeRange(0, attrStr.length)
            )
            self.attributedString = attrStr
        }
    }
    
    override public func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()
        context.textPosition = self.position
        CTLineDraw(line, context)
        context.restoreGState()
    }
}

// MARK: - MathAtomListDisplay
final class MathAtomListDisplay : MathAtomDisplay {
    enum LinePosition : Int {
        /// Regular
        case regular
        /// Positioned at a subscript
        case `subscript`
        /// Positioned at a superscript
        case superscript
    }
    
    /// Where the line is positioned
    var type: LinePosition = .regular
    
    /// An array of MathAtomDisplays which are positioned relative to the position of the
    /// the current display.
    private(set) var subDisplays = [MathAtomDisplay]()
    
    /// If a subscript or superscript this denotes the location in the parent MTList. For a
    /// regular list this is NSNotFound
    var index: Int = 0
    
    init(
        withDisplays displays: [MathAtomDisplay],
        range: NSRange
    ) {
        super.init()
        self.subDisplays = displays
        self.position = CGPoint.zero
        self.type = .regular
        self.index = NSNotFound
        self.range = range
        self.recomputeDimensions()
    }
  
    override var textColor: LaTeXColor? {
        didSet {
            for displayAtom in subDisplays {
                displayAtom.textColor = displayAtom.localTextColor ?? textColor
            }
        }
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()
        context.translateBy(x: position.x, y: position.y)
        context.textPosition = CGPoint.zero
        subDisplays.forEach { $0.draw(context) }
        context.restoreGState()
    }

    func recomputeDimensions() {
        var max_ascent: CGFloat = 0
        var max_descent: CGFloat = 0
        var max_width: CGFloat = 0
        for atom in subDisplays {
            let ascent = max(0, atom.position.y + atom.ascent);
            if (ascent > max_ascent) {
                max_ascent = ascent;
            }
            
            let descent = max(0, 0 - (atom.position.y - atom.descent));
            if (descent > max_descent) {
                max_descent = descent;
            }
            
            let width = atom.width + atom.position.x;
            if (width > max_width) {
                max_width = width;
            }
        }
        self.ascent = max_ascent;
        self.descent = max_descent;
        self.width = max_width;
    }
}

// MARK: - MathFractionDisplay
final class MathFractionDisplay: MathAtomDisplay {
    
    /** A display representing the numerator of the fraction. Its position is relative
     to the parent and is not treated as a sub-display.
     */
    private(set) var numerator: MathAtomListDisplay?
    
    /** A display representing the denominator of the fraction. Its position is relative
     to the parent is not treated as a sub-display.
     */
    private(set) var denominator: MathAtomListDisplay?
    
    var numeratorUp: CGFloat = 0 {
        didSet {
            updateNumeratorPosition()
        }
    }
    var denominatorDown: CGFloat = 0 {
        didSet {
            updateDenominatorPosition()
        }
    }
    var linePosition: CGFloat = 0
    var lineThickness: CGFloat = 0
    
    init(
        withNumerator numerator: MathAtomListDisplay?,
        denominator: MathAtomListDisplay?,
        position:CGPoint,
        range: NSRange
    ) {
        super.init()
        self.numerator = numerator;
        self.denominator = denominator;
        self.position = position;
        self.range = range;
        assert(self.range.length == 1, "Fraction range length not 1 - range (\(range.location), \(range.length)")
    }
    
    override var ascent: CGFloat {
        set { super.ascent = newValue }
        get { numerator!.ascent + numeratorUp }
    }

    override var descent: CGFloat {
        set { super.descent = newValue }
        get { denominator!.descent + denominatorDown }
    }

    override var width:CGFloat {
        set { super.width = newValue }
        get { max(numerator!.width, denominator!.width) }
    }

    func updateDenominatorPosition() {
        guard denominator != nil else { return }
        denominator!.position = CGPointMake(self.position.x + (self.width - denominator!.width)/2, self.position.y - self.denominatorDown)
    }

    func updateNumeratorPosition() {
        guard numerator != nil else { return }
        numerator!.position = CGPointMake(self.position.x + (self.width - numerator!.width)/2, self.position.y + self.numeratorUp)
    }

    override var position: CGPoint {
        set {
            super.position = newValue
            self.updateDenominatorPosition()
            self.updateNumeratorPosition()
        }
        get { super.position }
    }
    
    override var textColor: LaTeXColor? {
        set {
            super.textColor = newValue
            numerator?.textColor = newValue
            denominator?.textColor = newValue
        }
        get { super.textColor }
    }

    override func draw(_ context:CGContext) {
        super.draw(context)
        numerator?.draw(context)
        denominator?.draw(context)
        context.saveGState()
        textColor?.setStroke()
        if self.lineThickness > 0 {
            let path = LaTeXBezierPath()
            path.move(to: CGPointMake(self.position.x, self.position.y + self.linePosition))
            path.addLine(to: CGPointMake(self.position.x + self.width, self.position.y + self.linePosition))
            path.lineWidth = self.lineThickness
            path.stroke()
        }
        context.restoreGState()
    }
}

// MARK: - MathRadicalDisplay
/// Rendering of an MathRadical as an MathAtomDisplay
final class MathRadicalDisplay: MathAtomDisplay {
    
    /** A display representing the radicand of the radical. Its position is relative
     to the parent is not treated as a sub-display.
     */
    private(set) var radicand: MathAtomListDisplay?
    
    /** A display representing the degree of the radical. Its position is relative
     to the parent is not treated as a sub-display.
     */
    private(set) var degree: MathAtomListDisplay?
    
    override var position: CGPoint {
        set {
            super.position = newValue
            self.updateRadicandPosition()
        }
        get { super.position }
    }
    
    override var textColor: LaTeXColor? {
        set {
            super.textColor = newValue
            self.radicand?.textColor = newValue
            self.degree?.textColor = newValue
        }
        get { super.textColor }
    }
    
    private var _radicalGlyph: MathAtomDisplay?
    private var _radicalShift: CGFloat = 0
    
    var topKern:CGFloat=0
    var lineThickness:CGFloat=0
    
    init(
        withRadicand radicand: MathAtomListDisplay?,
        glyph: MathAtomDisplay,
        position: CGPoint,
        range: NSRange
    ) {
        super.init()
        self.radicand = radicand
        _radicalGlyph = glyph
        _radicalShift = 0
        self.position = position
        self.range = range
    }

    func setDegree(_ degree: MathAtomListDisplay?, fontMetrics: MathFontMathTable?) {
        // sets up the degree of the radical
        var kernBefore = fontMetrics!.radicalKernBeforeDegree
        let kernAfter = fontMetrics!.radicalKernAfterDegree
        let raise = fontMetrics!.radicalDegreeBottomRaisePercent * (self.ascent - self.descent)

        // The layout is:
        // kernBefore, raise, degree, kernAfter, radical
        self.degree = degree

        // the radical is now shifted by kernBefore + degree.width + kernAfter
        _radicalShift = kernBefore + degree!.width + kernAfter
        if _radicalShift < 0 {
            // we can't have the radical shift backwards, so instead we increase the kernBefore such
            // that _radicalShift will be 0.
            kernBefore -= _radicalShift
            _radicalShift = 0
        }
        
        // Note: position of degree is relative to parent.
        self.degree!.position = CGPointMake(self.position.x + kernBefore, self.position.y + raise)
        // Update the width by the _radicalShift
        self.width = _radicalShift + _radicalGlyph!.width + self.radicand!.width;
        // update the position of the radicand
        self.updateRadicandPosition()
    }

    func updateRadicandPosition() {
        // The position of the radicand includes the position of the MathRadicalDisplay
        // This is to make the positioning of the radical consistent with fractions and
        // have the cursor position finding algorithm work correctly.
        // move the radicand by the width of the radical sign
        self.radicand!.position = CGPointMake(
            self.position.x + _radicalShift + _radicalGlyph!.width,
            self.position.y
        )
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        // draw the radicand & degree at its position
        self.radicand?.draw(context)
        self.degree?.draw(context)

        context.saveGState();
        self.textColor?.setStroke()
        self.textColor?.setFill()

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: self.position.x + _radicalShift, y: self.position.y);
        context.textPosition = CGPoint.zero

        // Draw the glyph.
        _radicalGlyph?.draw(context)

        // Draw the VBOX
        // for the kern of, we don't need to draw anything.
        let heightFromTop = topKern;

        // draw the horizontal line with the given thickness
        let path = LaTeXBezierPath()
        let lineStart = CGPointMake(_radicalGlyph!.width, self.ascent - heightFromTop - self.lineThickness / 2); // subtract half the line thickness to center the line
        let lineEnd = CGPointMake(lineStart.x + self.radicand!.width, lineStart.y);
        path.move(to: lineStart)
        path.addLine(to: lineEnd)
        path.lineWidth = lineThickness
        path.lineCapStyle = .round
        path.stroke()

        context.restoreGState();
    }
}

// MARK: - MathGlyphDisplay
final class MathGlyphDisplay: MathAtomDisplay {
    var glyph: CGGlyph!
    var font: MathFont?
    
    init(withGlpyh glyph: CGGlyph, range: NSRange, font: MathFont?) {
        super.init()
        self.font = font
        self.glyph = glyph
        self.position = CGPoint.zero
        self.range = range
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()
        self.textColor?.setFill()
        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: self.position.x, y: self.position.y - self.shiftDown)
        context.textPosition = CGPoint.zero
        var pos = CGPoint.zero
        CTFontDrawGlyphs(font!.ctFont, &glyph, &pos, 1, context)
        context.restoreGState()
    }

    override var ascent: CGFloat {
        set { super.ascent = newValue }
        get { super.ascent - self.shiftDown }
    }

    override var descent:CGFloat {
        set { super.descent = newValue }
        get { super.descent + self.shiftDown }
    }
}

// MARK: - MathGlyphConstructionDisplay
final class MathGlyphConstructionDisplay: MathAtomDisplay {
    var glyphs = [CGGlyph]()
    var positions = [CGPoint]()
    var font:MathFont?
    var numGlyphs:Int=0
    
    init(
        withGlyphs glyphs:[NSNumber?],
        offsets: [NSNumber?],
        font: MathFont?
    ) {
        super.init()
        assert(glyphs.count == offsets.count, "Glyphs and offsets need to match")
        self.numGlyphs = glyphs.count;
        self.glyphs = [CGGlyph](repeating: CGGlyph(), count: self.numGlyphs)
        self.positions = [CGPoint](repeating: CGPoint.zero, count: self.numGlyphs)
        for i in 0 ..< self.numGlyphs {
            self.glyphs[i] = glyphs[i]!.uint16Value
            self.positions[i] = CGPointMake(0, CGFloat(offsets[i]!.floatValue))
        }
        self.font = font
        self.position = CGPoint.zero
    }
    
    override func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()
        self.textColor?.setFill()
        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: self.position.x, y: self.position.y - self.shiftDown)
        context.textPosition = CGPoint.zero
        // Draw the glyphs.
        CTFontDrawGlyphs(font!.ctFont, glyphs, positions, numGlyphs, context)
        context.restoreGState()
    }
    
    override var ascent: CGFloat {
        set { super.ascent = newValue }
        get { super.ascent - self.shiftDown }
    }

    override var descent: CGFloat {
        set { super.descent = newValue }
        get { super.descent + self.shiftDown }
    }
}

// MARK: - MathLargeOpLimitsDisplay
final class MathLargeOpLimitsDisplay: MathAtomDisplay {
    
    /** A display representing the upper limit of the large operator. Its position is relative
     to the parent is not treated as a sub-display.
     */
    var upperLimit: MathAtomListDisplay?
    
    /** A display representing the lower limit of the large operator. Its position is relative
     to the parent is not treated as a sub-display.
     */
    var lowerLimit: MathAtomListDisplay?
    
    var limitShift: CGFloat = 0
    var upperLimitGap: CGFloat = 0 {
        didSet {
            updateUpperLimitPosition()
        }
    }
    var lowerLimitGap: CGFloat = 0 {
        didSet {
            updateLowerLimitPosition()
        }
    }
    var extraPadding: CGFloat = 0

    var nucleus: MathAtomDisplay?
    
    init(
        withNucleus nucleus: MathAtomDisplay?,
        upperLimit: MathAtomListDisplay?,
        lowerLimit: MathAtomListDisplay?,
        limitShift: CGFloat,
        extraPadding:CGFloat
    ) {
        super.init()
        self.upperLimit = upperLimit;
        self.lowerLimit = lowerLimit;
        self.nucleus = nucleus;
        var maxWidth = max(nucleus!.width, upperLimit?.width ?? 0)
        maxWidth = max(maxWidth, lowerLimit?.width ?? 0)
        self.limitShift = limitShift;
        self.upperLimitGap = 0;
        self.lowerLimitGap = 0;
        self.extraPadding = extraPadding;  // corresponds to \xi_13 in TeX
        self.width = maxWidth;
    }

    override var ascent: CGFloat {
        set { super.ascent = newValue }
        get {
            if self.upperLimit != nil {
                return nucleus!.ascent + extraPadding + upperLimit!.ascent + upperLimitGap + upperLimit!.descent
            } else {
                return nucleus!.ascent
            }
        }
    }

    override var descent: CGFloat {
        set { super.descent = newValue }
        get {
            if self.lowerLimit != nil {
                return nucleus!.descent + extraPadding + lowerLimitGap + lowerLimit!.descent + lowerLimit!.ascent;
            } else {
                return nucleus!.descent;
            }
        }
    }
    
    override var position: CGPoint {
        set {
            super.position = newValue
            self.updateLowerLimitPosition()
            self.updateUpperLimitPosition()
            self.updateNucleusPosition()
        }
        get { super.position }
    }

    func updateLowerLimitPosition() {
        if self.lowerLimit != nil {
            // The position of the lower limit includes the position of the MTLargeOpLimitsDisplay
            // This is to make the positioning of the radical consistent with fractions and radicals
            // Move the starting point to below the nucleus leaving a gap of _lowerLimitGap and subtract
            // the ascent to to get the baseline. Also center and shift it to the left by _limitShift.
            self.lowerLimit!.position = CGPointMake(
                self.position.x - limitShift + (self.width - lowerLimit!.width) / 2,
                self.position.y - nucleus!.descent - lowerLimitGap - self.lowerLimit!.ascent
            )
        }
    }

    func updateUpperLimitPosition() {
        if upperLimit != nil {
            // The position of the upper limit includes the position of the MTLargeOpLimitsDisplay
            // This is to make the positioning of the radical consistent with fractions and radicals
            // Move the starting point to above the nucleus leaving a gap of _upperLimitGap and add
            // the descent to to get the baseline. Also center and shift it to the right by _limitShift.
            upperLimit!.position = CGPointMake(
                position.x + limitShift + (width - upperLimit!.width)/2,
                position.y + nucleus!.ascent + upperLimitGap + upperLimit!.descent
            )
        }
    }

    func updateNucleusPosition() {
        // Center the nucleus
        nucleus?.position = CGPointMake(
            position.x + (width - nucleus!.width) / 2,
            position.y
        )
    }
    
    override var textColor: LaTeXColor? {
        set {
            super.textColor = newValue
            self.upperLimit?.textColor = newValue
            self.lowerLimit?.textColor = newValue
            nucleus?.textColor = newValue
        }
        get { super.textColor }
    }

    override func draw(_ context:CGContext) {
        super.draw(context)
        // Draw the elements.
        self.upperLimit?.draw(context)
        self.lowerLimit?.draw(context)
        nucleus?.draw(context)
    }
    
}

// MARK: - MTLineDisplay
/// Rendering of an list with an overline or underline
class MathLineDisplay : MathAtomDisplay {
    
    /** A display representing the inner list that is underlined. Its position is relative
     to the parent is not treated as a sub-display.
     */
    var inner: MathAtomListDisplay?
    var lineShiftUp: CGFloat = 0
    var lineThickness:CGFloat = 0
    
    init(
        withInner inner:MathAtomListDisplay?,
        position: CGPoint,
        range: NSRange
    ) {
        super.init()
        self.inner = inner
        self.position = position
        self.range = range
    }
    
    override var textColor: LaTeXColor? {
        set {
            super.textColor = newValue
            inner?.textColor = newValue
        }
        get { super.textColor }
    }
    
    override var position: CGPoint {
        set {
            super.position = newValue
            self.updateInnerPosition()
        }
        get { super.position }
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        self.inner?.draw(context)
        context.saveGState()
        self.textColor?.setStroke()
        // draw the horizontal line
        let path = LaTeXBezierPath()
        let lineStart = CGPointMake(self.position.x, self.position.y + self.lineShiftUp)
        let lineEnd = CGPointMake(lineStart.x + self.inner!.width, lineStart.y)
        path.move(to:lineStart)
        path.addLine(to: lineEnd)
        path.lineWidth = self.lineThickness
        path.stroke()
        context.restoreGState()
    }
    
    func updateInnerPosition() {
        self.inner?.position = CGPointMake(self.position.x, self.position.y)
    }
}

// MARK: - MathAccentDisplay
final class MathAccentDisplay: MathAtomDisplay {
    /** A display representing the inner list that is accented. Its position is relative
     to the parent is not treated as a sub-display.
     */
    var accentee:MathAtomListDisplay?
    
    /** A display representing the accent. Its position is relative to the current display.
     */
    var accent:MathGlyphDisplay?
    
    init(
        withAccent glyph: MathGlyphDisplay?,
        accentee:MathAtomListDisplay?,
        range: NSRange
    ) {
        super.init()
        self.accent = glyph
        self.accentee = accentee
        self.accentee?.position = CGPoint.zero
        self.range = range
    }
    
    override var textColor: LaTeXColor? {
        set {
            super.textColor = newValue
            accentee?.textColor = newValue
            accent?.textColor = newValue
        }
        get { super.textColor }
    }

    override var position: CGPoint {
        set {
            super.position = newValue
            self.updateAccenteePosition()
        }
        get { super.position }
    }

    func updateAccenteePosition() {
        self.accentee?.position = CGPointMake(self.position.x, self.position.y);
    }

    override func draw(_ context:CGContext) {
        super.draw(context)
        self.accentee?.draw(context)
        context.saveGState();
        context.translateBy(x: self.position.x, y: self.position.y);
        context.textPosition = CGPoint.zero
        self.accent?.draw(context)
        context.restoreGState();
    }
}
