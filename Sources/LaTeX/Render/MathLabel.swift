import Foundation
import CoreText

// MARK: - MathLabel
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
            do {
                mathAtomList = try MathAtomListBuilder.build(fromString: latex)
                self.errorLabel.isHidden = true
            } catch let error as MathParseError {
                mathAtomList = nil
                errorMessage = error as NSError
                self.errorLabel.text = errorMessage?.localizedDescription
                self.errorLabel.frame = self.bounds
                self.errorLabel.isHidden = !displayErrorInline
            } catch {
                mathAtomList = nil
                errorMessage = error as NSError
                self.errorLabel.text = errorMessage?.localizedDescription
                self.errorLabel.frame = self.bounds
                self.errorLabel.isHidden = !displayErrorInline
            }
            self.setNeedsLayout()
        }
    }
    
    /// Dùng để hiển thị lỗi nếu có khi phân tích cú pháp LaTeX
    private let errorLabel: LaTeXLabel = LaTeXLabel()
    private var errorMessage: NSError?
    public var displayErrorInline = true
    
    /// Font chữ sử dụng để render công thức toán học
    public var mathFont: MathFont = MathFontType.defaultMathFont {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    /// Kích thước font chữ
    @IBInspectable
    public var mathFontSize: CGFloat = 20 {
        didSet {
            mathFont = mathFont.copy(withSize: mathFontSize)
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
            self.setNeedsLayout()
        }
    }
    
    public var labelMode: MathMode = .display {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    private var currentStyle: LineStyle {
        switch labelMode {
            case .display: return .display
            case .inline: return .text
        }
    }
    
    public var textAlignment: MathAlignment = .left {
        didSet {
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
        self.invalidateIntrinsicContentSize()
        errorLabel.frame = self.bounds
        self.setNeedsDisplay()
    }
    
    func _sizeThatFits() -> CGSize {
        guard let displayList else { return .zero }
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
        _sizeThatFits()
    }
    
    override public var isFlipped: Bool { false }
    
    override public func layout() {
        self._layoutSubviews()
        super.layout()
    }
    #endif
    
    #if canImport(UIKit)
    override public var intrinsicContentSize: CGSize {
        _sizeThatFits()
    }
    
    override public func layoutSubviews() {
        _layoutSubviews()
    }
    #endif
}

// MARK: - Inner Data Structures
extension MathLabel {
    /// Các chế độ hiển thị toán học
    public enum MathMode {
        /// `Inline Math Mode` - Chế độ toán học nội dòng
        /// Tương đương với `$` trong TeX.
        /// Công thức toán học được đặt trong cùng một dòng với văn bản xung quanh. Nó được coi như một phần của đoạn văn bản.
        /// TeX sẽ cố gắng định dạng công thức sao cho nó không làm ảnh hưởng quá nhiều đến chiều cao của dòng văn bản.
        case inline
        
        /// `Display Math Mode` - Chế độ toán học hiển thị riêng
        /// Tương đương với `$$` trong TeX.
        /// Công thức toán học được đặt trên một dòng riêng biệt, tách biệt khỏi văn bản xung quanh
        /// TeX sử dụng định dạng đầy đủ, đẹp mắt hơn cho các ký hiệu.
        case display
    }
    
    /// Các kiểu căn chỉnh nội dung cho công thức toán học
    public enum MathAlignment {
        /// Căn trái
        case left
        /// Căn giữa
        case center
        /// Căn phải
        case right
    }
}
