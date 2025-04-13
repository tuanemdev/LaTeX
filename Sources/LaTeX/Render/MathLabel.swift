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
    /// Phần view render nội bộ cho các toán tử
    private var displayList: MathAtomListDisplay?
    
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
    
    /// Font chữ sử dụng để render công thức toán học
    public var mathFont: MathFont? = MathFontManager.fontManager.defaultFont {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
    /// Kích thước font chữ
    @IBInspectable
    public var mathFontSize: CGFloat = 20 {
        didSet {
            mathFont = mathFont?.copy(withSize: mathFontSize)
        }
    }
    
    /// Màu chữ
    @IBInspectable
    public var textColor: LaTeXColor = LaTeXColor.black {
        didSet {
            self.displayList?.textColor = textColor
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable
    public var contentInsets: LaTeXEdgeInsets = zeroInsets {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
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
    
    public var textAlignment: TextAlignment = .left {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
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
        self.backgroundColor = LaTeXColor.clear
        self.errorLabel.textColor = LaTeXColor.red
        self.addSubview(errorLabel)
    }
    
    override public func draw(_ dirtyRect: LaTeXRect) {
        super.draw(dirtyRect)
        guard let displayList,
              let context = currentContext
        else { return }
        context.saveGState()
        displayList.draw(context)
        context.restoreGState()
    }
    
    func _layoutSubviews() {
        if let mathAtomList,
           let displayList = MTTypesetter.createLineForMathAtomList(mathAtomList, font: mathFont, style: currentStyle) {
            displayList.textColor = textColor
            var textX = CGFloat(0)
            switch self.textAlignment {
            case .left:
                textX = contentInsets.left
            case .center:
                textX = (bounds.size.width - contentInsets.left - contentInsets.right - displayList.width) / 2 + contentInsets.left
            case .right:
                textX = bounds.size.width - displayList.width - contentInsets.right
            }
            let availableHeight = bounds.size.height - contentInsets.bottom - contentInsets.top
            
            // center things vertically
            var height = displayList.ascent + displayList.descent
            if height < mathFontSize / 2 {
                height = mathFontSize / 2
            }
            let textY = (availableHeight - height) / 2 + displayList.descent + contentInsets.bottom
            displayList.position = CGPointMake(textX, textY)
            
            self.displayList = displayList
        } else {
            displayList = nil
        }
        errorLabel.frame = self.bounds
        self.setNeedsDisplay()
    }
    
    func _sizeThatFits(_ size: CGSize) -> CGSize {
        guard let displayList else { return size }
        let width = displayList.width + contentInsets.left + contentInsets.right
        let height = displayList.ascent + displayList.descent + contentInsets.top + contentInsets.bottom
        return CGSize(width: width, height: height)
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
