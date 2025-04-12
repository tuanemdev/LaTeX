import Foundation
import CoreText

public enum MathLabelMode {
    /// Equivalent to $$ in TeX
    case display
    /// Equivalent to $ in TeX.
    case text
}

public enum TextAlignment {
    case left
    case center
    case right
}

@IBDesignable
public class MathLabel: LaTeXView {
    /// Danh sách các toán tử trong công thức toán học
    private var mathAtomList: MathAtomList?
    
    /// Mã LaTeX
    @IBInspectable
    public var latex: String = "" {
        didSet {
            errorMessage = nil
            mathAtomList = MathAtomListBuilder.build(fromString: latex, error: &errorMessage)
            if let errorMessage {
                mathAtomList = nil
                self.errorLabel.text = errorMessage.localizedDescription
                self.errorLabel.frame = self.bounds
                self.errorLabel.isHidden = !displayErrorInline
            } else {
                self.errorLabel.isHidden = true
            }
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
    /// Dùng để hiển thị lỗi nếu có khi phân tích cú pháp LaTeX
    private let errorLabel: LaTeXLabel = LaTeXLabel()
    private var errorMessage: NSError?
    public var displayErrorInline = true
    
    /** The MTFont to use for rendering. */
    public var font:MTFont? {
        set {
            guard newValue != nil else { return }
            _font = newValue
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
        get { _font }
    }
    private var _font:MTFont?
    
    /** Convenience method to just set the size of the font without changing the fontface. */
    @IBInspectable
    public var fontSize:CGFloat {
        set {
            _fontSize = newValue
            let font = font?.copy(withSize: newValue)
            self.font = font  // also forces an update
        }
        get { _fontSize }
    }
    private var _fontSize:CGFloat=0
    
    /** This sets the text color of the rendered math formula. The default color is black. */
    @IBInspectable
    public var textColor:LaTeXColor? {
        set {
            guard newValue != nil else { return }
            _textColor = newValue
            self.displayList?.textColor = newValue
            self.setNeedsDisplay()
        }
        get { _textColor }
    }
    private var _textColor:LaTeXColor?
    
    /** The minimum distance from the margin of the view to the rendered math. This value is
     `UIEdgeInsetsZero` by default. This is useful if you need some padding between the math and
     the border/background color. sizeThatFits: will have its returned size increased by these insets.
     */
    @IBInspectable
    public var contentInsets: LaTeXEdgeInsets {
        set {
            _contentInsets = newValue
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
        get { _contentInsets }
    }
    private var _contentInsets = zeroInsets
    
    /** The Label mode for the label. The default mode is Display */
    public var labelMode: MathLabelMode = .display {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
    private var currentStyle: LineStyle {
        switch labelMode {
            case .display: return .display
            case .text: return .text
        }
    }
    
    /** Horizontal alignment for the text. The default is align left. */
    public var textAlignment:TextAlignment {
        set {
            _textAlignment = newValue
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
        get { _textAlignment }
    }
    private var _textAlignment = TextAlignment.left
    
    /** The internal display of the MTMathUILabel. This is for advanced use only. */
    public var displayList: MathAtomListDisplay? { _displayList }
    private var _displayList:MathAtomListDisplay?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initCommon()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initCommon()
    }
    
    func initCommon() {
        #if os(macOS)
        self.layer?.isGeometryFlipped = true
        #else
        self.layer.isGeometryFlipped = true
        #endif
        _fontSize = 20
        _contentInsets = zeroInsets
        labelMode = .display
        let font = MTFontManager.fontManager.defaultFont
        self.font = font
        _textAlignment = .left
        _displayList = nil
        displayErrorInline = true
        self.backgroundColor = LaTeXColor.clear
        
        _textColor = LaTeXColor.black
        errorLabel.isHidden = true
        errorLabel.textColor = LaTeXColor.red
        self.addSubview(errorLabel)
    }
    
    override public func draw(_ dirtyRect: LaTeXRect) {
        super.draw(dirtyRect)
        if self.mathAtomList == nil { return }

        // drawing code
        let context = currentContext!
        context.saveGState()
        displayList!.draw(context)
        context.restoreGState()
    }
    
    func _layoutSubviews() {
        if mathAtomList != nil {
            _displayList = MTTypesetter.createLineForMathAtomList(mathAtomList, font: font, style: currentStyle)
            _displayList!.textColor = textColor
            var textX = CGFloat(0)
            switch self.textAlignment {
                case .left:   textX = contentInsets.left
                case .center: textX = (bounds.size.width - contentInsets.left - contentInsets.right - _displayList!.width) / 2 + contentInsets.left
                case .right:  textX = bounds.size.width - _displayList!.width - contentInsets.right
            }
            let availableHeight = bounds.size.height - contentInsets.bottom - contentInsets.top
            
            // center things vertically
            var height = _displayList!.ascent + _displayList!.descent
            if height < fontSize/2 {
                height = fontSize/2  // set height to half the font size
            }
            let textY = (availableHeight - height) / 2 + _displayList!.descent + contentInsets.bottom
            _displayList!.position = CGPointMake(textX, textY)
        } else {
            _displayList = nil
        }
        errorLabel.frame = self.bounds
        self.setNeedsDisplay()
    }
    
    func _sizeThatFits(_ size: CGSize) -> CGSize {
        guard mathAtomList != nil else { return size }
        var size = size
        var displayList:MathAtomListDisplay? = nil
        displayList = MTTypesetter.createLineForMathAtomList(mathAtomList, font: font, style: currentStyle)
        size.width = displayList!.width + contentInsets.left + contentInsets.right
        size.height = displayList!.ascent + displayList!.descent + contentInsets.top + contentInsets.bottom
        return size
    }
    
    #if canImport(AppKit)
    func setNeedsDisplay() {
        self.needsDisplay = true
    }
    
    func setNeedsLayout() {
        self.needsLayout = true
    }
    
    override public var fittingSize: CGSize {
        _sizeThatFits(CGSizeZero)
    }
    
    override public var isFlipped: Bool { false }
    
    override public func layout() {
        self._layoutSubviews()
        super.layout()
    }
    #endif
    
    #if canImport(UIKit)
    override public var intrinsicContentSize: CGSize {
        _sizeThatFits(CGSizeZero)
    }
    
    override public func layoutSubviews() {
        _layoutSubviews()
    }
    #endif
}
