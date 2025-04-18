import Foundation

public class MathAtomList {
    /// Danh sách các toán tử
    public var atoms: [MathAtom] = []
    
    // MARK: - Initializers
    public init() { }
    
    public init(atoms: [MathAtom]) {
        self.atoms = atoms
    }
    
    public init(atom: MathAtom) {
        self.atoms = [atom]
    }
    
    init?(_ list: MathAtomList?) {
        guard let list = list else { return nil }
        self.atoms = list.atoms.map { $0.deepCopy() }
    }
    
    /// Tạo một danh sách toán tử mới như một biểu thức cuối cùng và cập nhật các toán tử
    /// bằng cách kết hợp các nguyên tử giống nhau xuất hiện liền nhau và chuyển đổi các toán tử một ngôi thành toán tử hai ngôi.
    /// Hàm này không sửa đổi MathAtomList hiện tại
    public var finalized: MathAtomList {
        let finalizedList = MathAtomList()
        let zeroRange = NSMakeRange(0, 0)
        
        var prevNode: MathAtom? = nil
        for atom in atoms {
            let newNode = atom.finalized
            
            if NSEqualRanges(zeroRange, atom.indexRange) {
                let index = prevNode == nil ? 0 : prevNode!.indexRange.location + prevNode!.indexRange.length
                newNode.indexRange = NSMakeRange(index, 1)
            }
            
            switch newNode.type {
            case .binaryOperator:
                if prevNode?.type.isNotBinaryOperator ?? true {
                    newNode.type = .unaryOperator
                }
            case .relation, .punctuation, .close:
                if prevNode != nil && prevNode!.type == .binaryOperator {
                    prevNode!.type = .unaryOperator
                }
            case .number:
                if prevNode != nil && prevNode!.type == .number && prevNode!.subScript == nil,
                   prevNode!.superScript == nil {
                    prevNode!.fuse(with: newNode)
                    continue
                }
            default:
                break
            }
            finalizedList.add(newNode)
            prevNode = newNode
        }
        if prevNode != nil && prevNode!.type == .binaryOperator {
            prevNode!.type = .unaryOperator
        }
        return finalizedList
    }
    
    public func add(_ atom: MathAtom?) {
        guard let atom = atom else { return }
        if isAtomAllowed(atom) {
            atoms.append(atom)
        } else {
            fatalError("Cannot add atom of type \(atom.type.rawValue) into MathAtomList")
        }
    }
    
    public func insert(_ atom: MathAtom?, at index: Int) {
        guard let atom = atom else { return }
        guard atoms.indices.contains(index) || index == atoms.endIndex else { return }
        if isAtomAllowed(atom) {
            atoms.insert(atom, at: index)
        } else {
            fatalError("Cannot add atom of type \(atom.type.rawValue) into MathAtomList")
        }
    }
    
    public func append(_ list: MathAtomList?) {
        guard let list = list else { return }
        atoms += list.atoms
    }
    
    func isAtomAllowed(_ atom: MathAtom?) -> Bool {
        atom?.type != .boundary
    }
}

// MARK: - NSCopying
extension MathAtomList: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathAtomList()
        copy.atoms = self.atoms.map { $0.deepCopy() }
        return copy
    }
    
    public func deepCopy() -> MathAtomList {
        copy() as! MathAtomList
    }
}

// MARK: - CustomStringConvertible
extension MathAtomList: CustomStringConvertible {
    public var description: String {
        atoms.description
    }
}
