//
//  File.swift
//  LaTeX
//
//  Created by Nguyen Tuan Anh on 12/4/25.
//

import Foundation
/**
    Alignment for a column of MTMathTable
 */
public enum ColumnAlignment {
    case left
    case center
    case right
}

// MARK: - MTMathTable
/** An atom representing an table element. This atom is not like other
 atoms and is not present in TeX. We use it to represent the `\halign` command
 in TeX with some simplifications. This is used for matrices, equation
 alignments and other uses of multiline environments.
 
 The cells in the table are represented as a two dimensional array of
 `MathAtomList` objects. The `MathAtomList`s could be empty to denote a missing
 value in the cell. Additionally an array of alignments indicates how each
 column will be aligned.
 */
public class MathTable: MathAtom {
    /// The alignment for each column (left, right, center). The default alignment
    /// for a column (if not set) is center.
    public var alignments = [ColumnAlignment]()
    /// The cells in the table as a two dimensional array.
    public var cells = [[MathAtomList]]()
    /// The name of the environment that this table denotes.
    public var environment = ""
    /// Spacing between each column in mu units.
    public var interColumnSpacing: CGFloat = 0
    /// Additional spacing between rows in jots (one jot is 0.3 times font size).
    /// If the additional spacing is 0, then normal row spacing is used are used.
    public var interRowAdditionalSpacing: CGFloat = 0
    
    init(environment: String?) {
        super.init()
        self.type = .table
        self.environment = environment ?? ""
    }
    
    override init() {
        super.init()
        self.type = .table
    }
    
    override public var finalized: MathAtom {
        let table = super.finalized as! MathTable
        for var row in table.cells {
            for i in 0..<row.count {
                row[i] = row[i].finalized
            }
        }
        return table
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MathTable()
        copy.type = self.type
        copy.nucleus = self.nucleus
        copy.subScript = self.subScript?.deepCopy()
        copy.superScript = self.superScript?.deepCopy()
        copy.indexRange = self.indexRange
        copy.fontStyle = self.fontStyle
        copy.fusedAtoms = self.fusedAtoms.map { $0.deepCopy() }
        copy.alignments = self.alignments
        copy.interRowAdditionalSpacing = self.interRowAdditionalSpacing
        copy.interColumnSpacing = self.interColumnSpacing
        copy.environment = self.environment
        copy.cells = self.cells.map { $0.map { $0.deepCopy() } }
        return copy
    }
    
    /// Set the value of a given cell. The table is automatically resized to contain this cell.
    public func set(cell list: MathAtomList, forRow row:Int, column:Int) {
        if self.cells.count <= row {
            for _ in self.cells.count...row {
                self.cells.append([])
            }
        }
        let rows = self.cells[row].count
        if rows <= column {
            for _ in rows...column {
                self.cells[row].append(MathAtomList())
            }
        }
        self.cells[row][column] = list
    }
    
    /// Set the alignment of a particular column. The table is automatically resized to
    /// contain this column and any new columns added have their alignment set to center.
    public func set(alignment: ColumnAlignment, forColumn col: Int) {
        if self.alignments.count <= col {
            for _ in self.alignments.count...col {
                self.alignments.append(ColumnAlignment.center)
            }
        }
        
        self.alignments[col] = alignment
    }
    
    /// Gets the alignment for a given column. If the alignment is not specified it defaults
    /// to center.
    public func get(alignmentForColumn col: Int) -> ColumnAlignment {
        if self.alignments.count <= col {
            return ColumnAlignment.center
        } else {
            return self.alignments[col]
        }
    }
    
    public var numColumns: Int {
        var numberOfCols = 0
        for row in self.cells {
            numberOfCols = max(numberOfCols, row.count)
        }
        return numberOfCols
    }
    
    public var numRows: Int { self.cells.count }
}
