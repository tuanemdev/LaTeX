import Foundation

struct MathEnvProperties {
    var envName: String?
    var ended: Bool
    var numRows: Int
    
    init(name: String?) {
        self.envName = name
        self.numRows = 0
        self.ended = false
    }
}

/**
 The error encountered when parsing a LaTeX string.
 */
public enum MathParseError: Error, CustomStringConvertible {
    /// The braces { } do not match.
    case mismatchBraces(String)
    /// A command in the string is not recognized.
    case invalidCommand(String)
    /// An expected character such as ] was not found.
    case characterNotFound(String)
    /// The \left or \right command was not followed by a delimiter.
    case missingDelimiter(String)
    /// The delimiter following \left or \right was not a valid delimiter.
    case invalidDelimiter(String)
    /// There is no \right corresponding to the \left command.
    case missingRight(String)
    /// There is no \left corresponding to the \right command.
    case missingLeft(String)
    /// The environment given to the \begin command is not recognized
    case invalidEnv(String)
    /// A command is used which is only valid inside a \begin,\end environment
    case missingEnv(String)
    /// There is no \begin corresponding to the \end command.
    case missingBegin(String)
    /// There is no \end corresponding to the \begin command.
    case missingEnd(String)
    /// The number of columns do not match the environment
    case invalidNumColumns(String)
    /// Internal error, due to a programming mistake.
    case internalError(String)
    /// Limit control applied incorrectly
    case invalidLimits(String)
    
    public var description: String {
        switch self {
        case .mismatchBraces(let msg),
             .invalidCommand(let msg),
             .characterNotFound(let msg),
             .missingDelimiter(let msg),
             .invalidDelimiter(let msg),
             .missingRight(let msg),
             .missingLeft(let msg),
             .invalidEnv(let msg),
             .missingEnv(let msg),
             .missingBegin(let msg),
             .missingEnd(let msg),
             .invalidNumColumns(let msg),
             .internalError(let msg),
             .invalidLimits(let msg):
            return msg
        }
    }
}

/// Khởi tạo một MathAtomList từ một chuỗi LaTeX
public struct MathAtomListBuilder {
    /// Chuỗi LaTeX cần phân tích cú pháp
    private let string: String
    /// Chỉ số hiện tại trong chuỗi
    private var currentCharIndex: String.Index
    /// Toán tử hiện tại
    private var currentInnerAtom: MathInner?
    /// Môi trường hiện tại
    private var currentEnv: MathEnvProperties?
    /// Kiểu phông chữ hiện tại
    private var currentFontStyle: MathFontStyle
    /// Có cho phép khoảng trắng không?
    private var spacesAllowed: Bool
    
    private var hasCharacters: Bool { currentCharIndex < string.endIndex }
    
    init(string: String) {
        self.string = string
        self.currentCharIndex = string.startIndex
        self.currentFontStyle = .defaultStyle
        self.spacesAllowed = false
    }
    
    // gets the next character and increments the index
    mutating func getNextCharacter() -> Character {
        assert(self.hasCharacters, "Retrieving character at index \(self.currentCharIndex) beyond length \(self.string.count)")
        let ch = string[currentCharIndex]
        currentCharIndex = string.index(after: currentCharIndex)
        return ch
    }
    
    mutating func unlookCharacter() {
        assert(currentCharIndex > string.startIndex, "Unlooking when at the first character.")
        if currentCharIndex > string.startIndex {
            currentCharIndex = string.index(before: currentCharIndex)
        }
    }
    
    mutating func expectCharacter(_ ch: Character) -> Bool {
        MTAssertNotSpace(ch)
        self.skipSpaces()
        
        if self.hasCharacters {
            let nextChar = self.getNextCharacter()
            MTAssertNotSpace(nextChar)
            if nextChar == ch {
                return true
            } else {
                self.unlookCharacter()
                return false
            }
        }
        return false
    }
    
    // MARK: - MathAtomList builder functions
    static func build(fromString string: String) throws(MathParseError) -> MathAtomList {
        var builder = MathAtomListBuilder(string: string)
        return try builder.build()
    }
    
    /// Builds a MathAtomList from the internal `string`.
    private mutating func build() throws(MathParseError) -> MathAtomList {
        let list = try self.buildInternal(false)
        if self.hasCharacters {
            throw MathParseError.mismatchBraces("Mismatched braces: \(self.string)")
        }
        return list
    }
    
    private mutating func buildInternal(_ oneCharOnly: Bool, stopChar stop: Character? = nil) throws(MathParseError) -> MathAtomList {
        let list = MathAtomList()
        assert(!(oneCharOnly && stop != nil), "Cannot set both oneCharOnly and stopChar.")
        var prevAtom: MathAtom? = nil
        while self.hasCharacters {
            var atom: MathAtom? = nil
            let char = self.getNextCharacter()
            
            if oneCharOnly {
                if char == "^" || char == "}" || char == "_" || char == "&" {
                    // this is not the character we are looking for.
                    // They are meant for the caller to look at.
                    self.unlookCharacter()
                    return list
                }
            }
            // If there is a stop character, keep scanning 'til we find it
            if stop != nil && char == stop! {
                return list
            }
            
            if char == "^" {
                assert(!oneCharOnly, "This should have been handled before")
                if (prevAtom == nil || prevAtom!.superScript != nil || !prevAtom!.isScriptAllowed) {
                    // If there is no previous atom, or if it already has a superscript
                    // or if scripts are not allowed for it, then add an empty node.
                    prevAtom = MathAtom(type: .ordinary, value: "")
                    list.add(prevAtom!)
                }
                // this is a superscript for the previous atom
                // note: if the next char is the stopChar it will be consumed by the ^ and so it doesn't count as stop
                prevAtom!.superScript = try self.buildInternal(true)
                continue
            } else if char == "_" {
                assert(!oneCharOnly, "This should have been handled before")
                if (prevAtom == nil || prevAtom!.subScript != nil || !prevAtom!.isScriptAllowed) {
                    // If there is no previous atom, or if it already has a subcript
                    // or if scripts are not allowed for it, then add an empty node.
                    prevAtom = MathAtom(type: .ordinary, value: "")
                    list.add(prevAtom!)
                }
                // this is a subscript for the previous atom
                // note: if the next char is the stopChar it will be consumed by the _ and so it doesn't count as stop
                prevAtom!.subScript = try self.buildInternal(true)
                continue
            } else if char == "{" {
                // this puts us in a recursive routine, and sets oneCharOnly to false and no stop character
                let subList = try self.buildInternal(false, stopChar: "}")
                prevAtom = subList.atoms.last
                list.append(subList)
                if oneCharOnly {
                    return list
                }
                continue
            } else if char == "}" {
                // \ means a command
                assert(!oneCharOnly, "This should have been handled before")
                assert(stop == nil, "This should have been handled before")
                // We encountered a closing brace when there is no stop set, that means there was no
                // corresponding opening brace.
                throw MathParseError.mismatchBraces("Mismatched braces.")
            } else if char == "\\" {
                let command = readCommand()
                if let done = try stopCommand(command, list:list, stopChar:stop) {
                    return done
                }
                
                if try self.applyModifier(command, atom:prevAtom) {
                    continue
                }
                
                if let fontStyle = MathAtomFactory.fontStyleWithName(command) {
                    let oldSpacesAllowed = spacesAllowed
                    // Text has special consideration where it allows spaces without escaping.
                    spacesAllowed = command == "text"
                    let oldFontStyle = currentFontStyle
                    currentFontStyle = fontStyle
                    let sublist = try self.buildInternal(true)
                    // Restore the font style.
                    currentFontStyle = oldFontStyle
                    spacesAllowed = oldSpacesAllowed
                    
                    prevAtom = sublist.atoms.last
                    list.append(sublist)
                    if oneCharOnly {
                        return list
                    }
                    continue
                }
                
                atom = try self.atomForCommand(command)
            } else if char == "&" {
                // used for column separation in tables
                assert(!oneCharOnly, "This should have been handled before")
                if self.currentEnv != nil {
                    return list
                } else {
                    // Create a new table with the current list and a default env
                    let table = try self.buildTable(env: nil, firstList: list, isRow: false)
                    return MathAtomList(atom: table)
                }
            } else if spacesAllowed && char == " " {
                // If spaces are allowed then spaces do not need escaping with a \ before being used.
                atom = MathAtomFactory.atom(forLatexSymbol: " ")
            } else {
                atom = MathAtomFactory.atom(forCharacter: char)
                if atom == nil {
                    // Not a recognized character
                    continue
                }
            }
            
            assert(atom != nil, "Atom shouldn't be nil")
            atom?.fontStyle = currentFontStyle
            list.add(atom)
            prevAtom = atom
            
            if oneCharOnly {
                return list
            }
        }
        if stop != nil {
            if stop == "}" {
                // We did not find a corresponding closing brace.
                throw MathParseError.mismatchBraces("Missing closing brace")
            } else {
                // we never found our stop character
                throw MathParseError.characterNotFound("Expected character not found: \(stop!)")
            }
        }
        return list
    }
    
    mutating func atomForCommand(_ command: String) throws(MathParseError) -> MathAtom {
        if let atom = MathAtomFactory.atom(forLatexSymbol: command) {
            return atom
        }
        if let accent = MathAtomFactory.accent(withName: command) {
            // The command is an accent
            accent.innerList = try self.buildInternal(true)
            return accent
        } else if command == "frac" {
            // A fraction command has 2 arguments
            let frac = MathFraction()
            frac.numerator = try self.buildInternal(true)
            frac.denominator = try self.buildInternal(true)
            return frac
        } else if command == "binom" {
            // A binom command has 2 arguments
            let frac = MathFraction(hasRule: false)
            frac.numerator = try self.buildInternal(true)
            frac.denominator = try self.buildInternal(true)
            frac.leftDelimiter = "("
            frac.rightDelimiter = ")"
            return frac
        } else if command == "sqrt" {
            // A sqrt command with one argument
            let rad = MathRadical()
            guard self.hasCharacters else {
                rad.radicand = try self.buildInternal(true)
                return rad
            }
            let ch = self.getNextCharacter()
            if (ch == "[") {
                // special handling for sqrt[degree]{radicand}
                rad.degree = try self.buildInternal(false, stopChar:"]")
                rad.radicand = try self.buildInternal(true)
            } else {
                self.unlookCharacter()
                rad.radicand = try self.buildInternal(true)
            }
            return rad
        } else if command == "left" {
            // Save the current inner while a new one gets built.
            let oldInner = currentInnerAtom
            currentInnerAtom = MathInner()
            currentInnerAtom!.leftBoundary = try self.getBoundaryAtom("left")
            currentInnerAtom!.innerList = try self.buildInternal(false)
            if currentInnerAtom!.rightBoundary == nil {
                // A right node would have set the right boundary so we must be missing the right node.
                throw MathParseError.missingRight("Missing \\right")
            }
            // reinstate the old inner atom.
            let newInner = currentInnerAtom
            currentInnerAtom = oldInner
            return newInner!
        } else if command == "overline" {
            // The overline command has 1 arguments
            let over = MathOverLine()
            over.innerList = try self.buildInternal(true)
            return over
        } else if command == "underline" {
            // The underline command has 1 arguments
            let under = MathUnderLine()
            under.innerList = try self.buildInternal(true)
            return under
        } else if command == "begin" {
            let env = try self.readEnvironment()
            let table = try self.buildTable(env: env, firstList: nil, isRow: false)
            return table
        } else if command == "color" {
            // A color command has 2 arguments
            let mathColor = MathColor()
            mathColor.colorString = try self.readColor()
            mathColor.innerList = try self.buildInternal(true)
            return mathColor
        } else if command == "textcolor" {
            // A textcolor command has 2 arguments
            let mathColor = MathTextColor()
            mathColor.colorString = try self.readColor()
            mathColor.innerList = try self.buildInternal(true)
            return mathColor
        } else if command == "colorbox" {
            // A color command has 2 arguments
            let mathColorbox = MathColorBox()
            mathColorbox.colorString = try self.readColor()
            mathColorbox.innerList = try self.buildInternal(true)
            return mathColorbox
        } else {
            throw MathParseError.invalidCommand("Invalid command \\\(command)")
        }
    }
    
    mutating func readColor() throws(MathParseError) -> String {
        if !self.expectCharacter("{") {
            // We didn't find an opening brace, so no env found.
            throw MathParseError.characterNotFound("Missing {")
        }
        
        // Ignore spaces and nonascii.
        self.skipSpaces()
        
        // a string of all upper and lower case characters.
        var mutable = ""
        while self.hasCharacters {
            let ch = self.getNextCharacter()
            if ch == "#" || (ch >= "A" && ch <= "F") || (ch >= "a" && ch <= "f") || (ch >= "0" && ch <= "9") {
                mutable.append(ch)
            } else {
                // we went too far
                self.unlookCharacter()
                break
            }
        }
        
        if !self.expectCharacter("}") {
            // We didn't find an closing brace, so invalid format.
            throw MathParseError.characterNotFound("Missing }")
        }
        return mutable
    }
    
    mutating func skipSpaces() {
        while self.hasCharacters {
            let ch = self.getNextCharacter().utf32Char
            if ch < 0x21 || ch > 0x7E {
                // skip non ascii characters and spaces
                continue
            } else {
                self.unlookCharacter()
                return
            }
        }
    }
    
    static var fractionCommands: [String:[Character]] {
        [
            "over": [],
            "atop": [],
            "choose": ["(", ")"],
            "brack": ["[", "]"],
            "brace": ["{", "}"]
        ]
    }
    
    mutating func stopCommand(_ command: String, list: MathAtomList, stopChar: Character?) throws(MathParseError) -> MathAtomList? {
        if command == "right" {
            if currentInnerAtom == nil {
                throw MathParseError.missingLeft("Missing \\left")
            }
            currentInnerAtom!.rightBoundary = try self.getBoundaryAtom("right")
            // return the list read so far.
            return list
        } else if let delims = Self.fractionCommands[command] {
            var frac: MathFraction! = nil
            if command == "over" {
                frac = MathFraction()
            } else {
                frac = MathFraction(hasRule: false)
            }
            if delims.count == 2 {
                frac.leftDelimiter = String(delims[0])
                frac.rightDelimiter = String(delims[1])
            }
            frac.numerator = list
            frac.denominator = try self.buildInternal(false, stopChar: stopChar)
            let fracList = MathAtomList()
            fracList.add(frac)
            return fracList
        } else if command == "\\" || command == "cr" {
            if currentEnv != nil {
                // Stop the current list and increment the row count
                currentEnv!.numRows += 1
                return list
            } else {
                // Create a new table with the current list and a default env
                let table = try self.buildTable(env: nil, firstList: list, isRow: true)
                return MathAtomList(atom: table)
            }
        } else if command == "end" {
            if currentEnv == nil {
                throw MathParseError.missingBegin("Missing \\begin")
            }
            let env = try self.readEnvironment()
            if env != currentEnv!.envName {
                throw MathParseError.invalidEnv("Begin environment name \(currentEnv!.envName ?? "") does not match end name: \(env)")
            }
            // Finish the current environment.
            currentEnv!.ended = true
            return list
        }
        return nil
    }
    
    // Applies the modifier to the atom. Returns true if modifier applied.
    mutating func applyModifier(_ modifier: String, atom: MathAtom?) throws(MathParseError) -> Bool {
        if modifier == "limits" {
            if atom?.type != .largeOperator {
                throw MathParseError.invalidLimits("Limits can only be applied to an operator.")
            } else {
                let op = atom as! MathLargeOperator
                op.limits = true
            }
            return true
        } else if modifier == "nolimits" {
            if atom?.type != .largeOperator {
                throw MathParseError.invalidLimits("No limits can only be applied to an operator.")
            } else {
                let op = atom as! MathLargeOperator
                op.limits = false
            }
            return true
        }
        return false
    }
    
    mutating func readEnvironment() throws(MathParseError) -> String {
        if !self.expectCharacter("{") {
            // We didn't find an opening brace, so no env found.
            throw MathParseError.characterNotFound("Missing {")
        }
        
        self.skipSpaces()
        let env = self.readString()
        
        if !self.expectCharacter("}") {
            // We didn"t find an closing brace, so invalid format.
            throw MathParseError.characterNotFound("Missing }")
        }
        return env
    }
    
    func MTAssertNotSpace(_ ch: Character) {
        assert(ch >= "\u{21}" && ch <= "\u{7E}", "Expected non-space character \(ch)")
    }
    
    mutating func buildTable(env: String?, firstList: MathAtomList?, isRow: Bool) throws(MathParseError) -> MathAtom {
        // Save the current env till an new one gets built.
        let oldEnv = self.currentEnv
        
        currentEnv = MathEnvProperties(name: env)
        
        var currentRow = 0
        var currentCol = 0
        
        var rows = [[MathAtomList]]()
        rows.append([MathAtomList]())
        if firstList != nil {
            rows[currentRow].append(firstList!)
            if isRow {
                currentEnv!.numRows += 1
                currentRow += 1
                rows.append([MathAtomList]())
            } else {
                currentCol += 1
            }
        }
        while !currentEnv!.ended && self.hasCharacters {
            let list = try self.buildInternal(false)
            rows[currentRow].append(list)
            currentCol += 1
            if currentEnv!.numRows > currentRow {
                currentRow = currentEnv!.numRows
                rows.append([MathAtomList]())
                currentCol = 0
            }
        }
        
        if !currentEnv!.ended && currentEnv!.envName != nil {
            throw MathParseError.missingEnd("Missing \\end")
        }
        
        // Call the updated throwing table function
        let table = try MathAtomFactory.table(withEnvironment: currentEnv?.envName, rows: rows)
        
        self.currentEnv = oldEnv
        return table
    }
    
    mutating func getBoundaryAtom(_ delimiterType: String) throws(MathParseError) -> MathAtom {
        let delim = try self.readDelimiter()
        guard let boundary = MathAtomFactory.boundary(forDelimiter: delim) else {
            throw MathParseError.invalidDelimiter("Invalid delimiter for \(delimiterType): \(delim)")
        }
        return boundary
    }
    
    mutating func readDelimiter() throws(MathParseError) -> String {
        self.skipSpaces()
        while self.hasCharacters {
            let char = self.getNextCharacter()
            MTAssertNotSpace(char)
            if char == "\\" {
                let command = self.readCommand()
                if command == "|" {
                    return "||"
                }
                return command
            } else {
                return String(char)
            }
        }
        throw MathParseError.missingDelimiter("Expected delimiter not found")
    }
    
    mutating func readCommand() -> String {
        let singleChars = "{}$#%_| ,>;!\\"
        if self.hasCharacters {
            let char = self.getNextCharacter()
            if let _ = singleChars.firstIndex(of: char) {
                return String(char)
            } else {
                self.unlookCharacter()
            }
        }
        return self.readString()
    }
    
    mutating func readString() -> String {
        // a string of all upper and lower case characters.
        var output = ""
        while self.hasCharacters {
            let char = self.getNextCharacter()
            if char.isLowercase || char.isUppercase {
                output.append(char)
            } else {
                self.unlookCharacter()
                break
            }
        }
        return output
    }
}
