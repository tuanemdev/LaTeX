import Foundation

/// Một toán tử toán học
public class MathAtom {
    /// Loại toán tử
    public var type: MathAtomType = .ordinary
    
    /// Hạt nhân
    public var nucleus: String = ""
    
    /// Danh sách toán tử dưới dòng
    public var subScript: MathAtomList? {
        didSet {
            if subScript != nil && !isScriptAllowed {
                fatalError("Subscripts not allowed for atom of type \(self.type)")
            }
        }
    }
    
    /// Danh sách toán tử trên dòng
    public var superScript: MathAtomList? {
        didSet {
            if superScript != nil && !isScriptAllowed {
                fatalError("Superscripts not allowed for atom of type \(self.type)")
            }
        }
    }
    
    /// Vị trí của toán tử trong chuỗi đầu vào
    public var indexRange = NSRange(location: 0, length: 0)
    
    /// Kiểu phông chữ của toán tử
    var fontStyle: MathFontStyle = .defaultStyle
    
    /// Nếu toán tử được hình thành từ nhiều toán tử khác, danh sách này sẽ chứa các toán tử đó
    var fusedAtoms = [MathAtom]()
    
    // MARK: - Hàm khởi tạo
    init() { }
    
    init(type: MathAtomType, value: String) {
        self.type = type
        switch type {
        case .radical, .fraction:
            self.nucleus = ""
        default:
            self.nucleus = value
        }
    }
    
    /// Bản sao chép hoàn thiện
    public var finalized: MathAtom {
        let finalized: MathAtom = self.deepCopy()
        finalized.superScript = finalized.superScript?.finalized
        finalized.subScript = finalized.subScript?.finalized
        return finalized
    }
    
    /// Kết hợp toán tử này với một toán tử khác
    func fuse(with atom: MathAtom) {
        assert(self.subScript == nil, "Cannot fuse into an atom which has a subscript: \(self)");
        assert(self.superScript == nil, "Cannot fuse into an atom which has a superscript: \(self)");
        assert(atom.type == self.type, "Only atoms of the same type can be fused. \(self), \(atom)");
        
        if self.fusedAtoms.isEmpty {
            self.fusedAtoms.append(self.deepCopy())
        }
        if !atom.fusedAtoms.isEmpty {
            self.fusedAtoms.append(contentsOf: atom.fusedAtoms)
        } else {
            self.fusedAtoms.append(atom)
        }
        
        self.nucleus += atom.nucleus
        self.indexRange.length += atom.indexRange.length
        self.superScript = atom.superScript
        self.subScript = atom.subScript
    }
    
    /// Kiểm tra toán tử này có thể có chỉ số trên hoặc dưới
    var isScriptAllowed: Bool { self.type.isScriptAllowed }
    
    var isNotBinaryOperator: Bool { self.type.isNotBinaryOperator }
}

// MARK: - NSCopying
extension MathAtom: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathAtom()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = MathAtomList(self.subScript)
        copy.superScript = MathAtomList(self.superScript)
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms
        return copy
    }
    
    public func deepCopy() -> MathAtom {
        self.copy(with: nil) as! MathAtom
    }
}

// MARK: - CustomStringConvertible
extension MathAtom: CustomStringConvertible {
    @objc
    public var description: String {
        var string = self.nucleus
        if self.superScript != nil {
            string += "^{\(self.superScript!.description)}"
        }
        if self.subScript != nil {
            string += "_{\(self.subScript!.description)}"
        }
        return string
    }
}
