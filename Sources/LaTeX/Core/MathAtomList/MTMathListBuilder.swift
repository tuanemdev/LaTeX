//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by Kostub Deshmukh.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import Foundation

/** `MathAtomListBuilder` is a class for parsing LaTeX into an `MathAtomList` that
 can be rendered and processed mathematically.
 */
struct MTEnvProperties {
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
 
 The `code` in the `NSError` is one of the following indicating why the LaTeX string
 could not be parsed.
 */
enum MTParseErrors:Int {
    /// The braces { } do not match.
    case mismatchBraces = 1
    /// A command in the string is not recognized.
    case invalidCommand
    /// An expected character such as ] was not found.
    case characterNotFound
    /// The \left or \right command was not followed by a delimiter.
    case missingDelimiter
    /// The delimiter following \left or \right was not a valid delimiter.
    case invalidDelimiter
    /// There is no \right corresponding to the \left command.
    case missingRight
    /// There is no \left corresponding to the \right command.
    case missingLeft
    /// The environment given to the \begin command is not recognized
    case invalidEnv
    /// A command is used which is only valid inside a \begin,\end environment
    case missingEnv
    /// There is no \begin corresponding to the \end command.
    case missingBegin
    /// There is no \end corresponding to the \begin command.
    case missingEnd
    /// The number of columns do not match the environment
    case invalidNumColumns
    /// Internal error, due to a programming mistake.
    case internalError
    /// Limit control applied incorrectly
    case invalidLimits
}

let MTParseError = "ParseError"

/** `MathAtomListBuilder` is a class for parsing LaTeX into an `MathAtomList` that
 can be rendered and processed mathematically.
 */
public struct MathAtomListBuilder {
    var string: String
    var currentCharIndex: String.Index
    var currentInnerAtom: MathInner?
    var currentEnv: MTEnvProperties?
    var currentFontStyle:MathFontStyle
    var spacesAllowed:Bool
    
    /** Contains any error that occurred during parsing. */
    var error:NSError?
    
    // MARK: - Character-handling routines
    
    var hasCharacters: Bool { currentCharIndex < string.endIndex }
    
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
    
    public static let spaceToCommands: [CGFloat: String] = [
        3 : ",",
        4 : ">",
        5 : ";",
        (-3) : "!",
        18 : "quad",
        36 : "qquad",
    ]
    
    nonisolated(unsafe) public static let styleToCommands: [LineStyle: String] = [
        .display: "displaystyle",
        .text: "textstyle",
        .script: "scriptstyle",
        .scriptOfScript: "scriptscriptstyle"
    ]
    
    init(string: String) {
        self.error = nil
        self.string = string
        self.currentCharIndex = string.startIndex
        self.currentFontStyle = .defaultStyle
        self.spacesAllowed = false
    }
    
    // MARK: - MathAtomList builder functions
    
    /// Builds a MathAtomList from the internal `string`. Returns nil if there is an error.
    public mutating func build() -> MathAtomList? {
        let list = self.buildInternal(false)
        if self.hasCharacters && error == nil {
            self.setError(.mismatchBraces, message: "Mismatched braces: \(self.string)")
            return nil
        }
        if error != nil {
            return nil
        }
        return list
    }
    
    /** Construct a math list from a given string. If there is parse error, returns
     nil. To retrieve the error use the function `MathAtomListBuilder.build(fromString:error:)`.
     */
    public static func build(fromString string: String) -> MathAtomList? {
        var builder = MathAtomListBuilder(string: string)
        return builder.build()
    }
    
    /** Construct a math list from a given string. If there is an error while
     constructing the string, this returns nil. The error is returned in the
     `error` parameter.
     */
    public static func build(fromString string: String, error:inout NSError?) -> MathAtomList? {
        var builder = MathAtomListBuilder(string: string)
        let output = builder.build()
        if builder.error != nil {
            error = builder.error
            return nil
        }
        return output
    }
    
    public mutating func buildInternal(_ oneCharOnly: Bool) -> MathAtomList? {
        self.buildInternal(oneCharOnly, stopChar: nil)
    }
    
    public mutating func buildInternal(_ oneCharOnly: Bool, stopChar stop: Character?) -> MathAtomList? {
        let list = MathAtomList()
        assert(!(oneCharOnly && stop != nil), "Cannot set both oneCharOnly and stopChar.")
        var prevAtom: MathAtom? = nil
        while self.hasCharacters {
            if error != nil { return nil } // If there is an error thus far then bail out.
            
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
                prevAtom!.superScript = self.buildInternal(true)
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
                prevAtom!.subScript = self.buildInternal(true)
                continue
            } else if char == "{" {
                // this puts us in a recursive routine, and sets oneCharOnly to false and no stop character
                if let subList = self.buildInternal(false, stopChar: "}") {
                    prevAtom = subList.atoms.last
                    list.append(subList)
                    if oneCharOnly {
                        return list
                    }
                }
                continue
            } else if char == "}" {
                // \ means a command
                assert(!oneCharOnly, "This should have been handled before")
                assert(stop == nil, "This should have been handled before")
                // We encountered a closing brace when there is no stop set, that means there was no
                // corresponding opening brace.
                self.setError(.mismatchBraces, message:"Mismatched braces.")
                return nil
            } else if char == "\\" {
                let command = readCommand()
                let done = stopCommand(command, list:list, stopChar:stop)
                if done != nil {
                    return done
                } else if error != nil {
                    return nil
                }
                if self.applyModifier(command, atom:prevAtom) {
                    continue
                }
                
                if let fontStyle = MathAtomFactory.fontStyleWithName(command) {
                    let oldSpacesAllowed = spacesAllowed
                    // Text has special consideration where it allows spaces without escaping.
                    spacesAllowed = command == "text"
                    let oldFontStyle = currentFontStyle
                    currentFontStyle = fontStyle
                    if let sublist = self.buildInternal(true) {
                        // Restore the font style.
                        currentFontStyle = oldFontStyle
                        spacesAllowed = oldSpacesAllowed
                        
                        prevAtom = sublist.atoms.last
                        list.append(sublist)
                        if oneCharOnly {
                            return list
                        }
                    }
                    continue
                }
                atom = self.atomForCommand(command)
                if atom == nil {
                    // this was an unknown command,
                    // we flag an error and return
                    // (note setError will not set the error if there is already one, so we flag internal error
                    // in the odd case that an _error is not set.
                    self.setError(.internalError, message:"Internal error")
                    return nil
                }
            } else if char == "&" {
                // used for column separation in tables
                assert(!oneCharOnly, "This should have been handled before")
                if self.currentEnv != nil {
                    return list
                } else {
                    // Create a new table with the current list and a default env
                    let table = self.buildTable(env: nil, firstList: list, isRow: false)
                    return MathAtomList(atom: table!)
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
                self.setError(.mismatchBraces, message:"Missing closing brace")
            } else {
                // we never found our stop character
                let errorMessage = "Expected character not found: \(stop!)"
                self.setError(.characterNotFound, message:errorMessage)
            }
        }
        return list
    }
    
    
    // MARK: - MathAtomList to LaTeX conversion
    
    /// This converts the MathAtomList to LaTeX.
    public static func MathAtomListToString(_ ml: MathAtomList?) -> String {
        var str = ""
        var currentfontStyle = MathFontStyle.defaultStyle
        if let atomList = ml {
            for atom in atomList.atoms {
                if currentfontStyle != atom.fontStyle {
                    if currentfontStyle != .defaultStyle {
                        str += "}"
                    }
                    if atom.fontStyle != .defaultStyle {
                        let fontStyleName = MathAtomFactory.fontNameForStyle(atom.fontStyle)
                        str += "\\\(fontStyleName){"
                    }
                    currentfontStyle = atom.fontStyle
                }
                if atom.type == .fraction {
                    if let frac = atom as? MathFraction {
                        if frac.hasRule {
                            str += "\\frac{\(MathAtomListToString(frac.numerator!))}{\(MathAtomListToString(frac.denominator!))}"
                        } else {
                            let command: String
                            if frac.leftDelimiter.isEmpty && frac.rightDelimiter.isEmpty {
                                command = "atop"
                            } else if frac.leftDelimiter == "(" && frac.rightDelimiter == ")" {
                                command = "choose"
                            } else if frac.leftDelimiter == "{" && frac.rightDelimiter == "}" {
                                command = "brace"
                            } else if frac.leftDelimiter == "[" && frac.rightDelimiter == "]" {
                                command = "brack"
                            } else {
                                command = "atopwithdelims\(frac.leftDelimiter)\(frac.rightDelimiter)"
                            }
                            str += "{\(MathAtomListToString(frac.numerator!)) \\\(command) \(MathAtomListToString(frac.denominator!))}"
                        }
                    }
                } else if atom.type == .radical {
                    str += "\\sqrt"
                    if let rad = atom as? MathRadical {
                        if rad.degree != nil {
                            str += "[\(MathAtomListToString(rad.degree!))]"
                        }
                        str += "{\(MathAtomListToString(rad.radicand!))}"
                    }
                } else if atom.type == .inner {
                    if let inner = atom as? MathInner {
                        if inner.leftBoundary != nil || inner.rightBoundary != nil {
                            if inner.leftBoundary != nil {
                                str += "\\left\(delimToString(delim: inner.leftBoundary!)) "
                            } else {
                                str += "\\left. "
                            }
                            
                            str += MathAtomListToString(inner.innerList!)
                            
                            if inner.rightBoundary != nil {
                                str += "\\right\(delimToString(delim: inner.rightBoundary!)) "
                            } else {
                                str += "\\right. "
                            }
                        } else {
                            str += "{\(MathAtomListToString(inner.innerList!))}"
                        }
                    }
                } else if atom.type == .table {
                    if let table = atom as? MathTable {
                        if !table.environment.isEmpty {
                            str += "\\begin{\(table.environment)}"
                        }
                        
                        for i in 0..<table.numRows {
                            let row = table.cells[i]
                            for j in 0..<row.count {
                                let cell = row[j]
                                if table.environment == "matrix" {
                                    if cell.atoms.count >= 1 && cell.atoms[0].type == .style {
                                        // remove first atom
                                        cell.atoms.removeFirst()
                                    }
                                }
                                if table.environment == "eqalign" || table.environment == "aligned" || table.environment == "split" {
                                    if j == 1 && cell.atoms.count >= 1 && cell.atoms[0].type == .ordinary && cell.atoms[0].nucleus.count == 0 {
                                        // remove empty nucleus added for spacing
                                        cell.atoms.removeFirst()
                                    }
                                }
                                str += MathAtomListToString(cell)
                                if j < row.count - 1 {
                                    str += "&"
                                }
                            }
                            if i < table.numRows - 1 {
                                str += "\\\\ "
                            }
                        }
                        if !table.environment.isEmpty {
                            str += "\\end{\(table.environment)}"
                        }
                    }
                } else if atom.type == .overline {
                    if let overline = atom as? MathOverLine {
                        str += "\\overline"
                        str += "{\(MathAtomListToString(overline.innerList!))}"
                    }
                } else if atom.type == .underline {
                    if let underline = atom as? MathUnderLine {
                        str += "\\underline"
                        str += "{\(MathAtomListToString(underline.innerList!))}"
                    }
                } else if atom.type == .accent {
                    if let accent = atom as? MathAccent {
                        str += "\\\(MathAtomFactory.accentName(accent)!){\(MathAtomListToString(accent.innerList!))}"
                    }
                } else if atom.type == .largeOperator {
                    let op = atom as! MathLargeOperator
                    let command = MathAtomFactory.latexSymbolName(for: atom)
                    let originalOp = MathAtomFactory.atom(forLatexSymbol: command!) as! MathLargeOperator
                    str += "\\\(command!) "
                    if originalOp.limits != op.limits {
                        if op.limits {
                            str += "\\limits "
                        } else {
                            str += "\\nolimits "
                        }
                    }
                } else if atom.type == .space {
                    if let space = atom as? MathSpace {
                        if let command = Self.spaceToCommands[space.space] {
                            str += "\\\(command) "
                        } else {
                            str += String(format: "\\mkern%.1fmu", space.space)
                        }
                    }
                } else if atom.type == .style {
                    if let style = atom as? MathStyle {
                        if let command = Self.styleToCommands[style.style] {
                            str += "\\\(command) "
                        }
                    }
                } else if atom.nucleus.isEmpty {
                    str += "{}"
                } else if atom.nucleus == "\u{2236}" {
                    // math colon
                    str += ":"
                } else if atom.nucleus == "\u{2212}" {
                    // math minus
                    str += "-"
                } else {
                    if let command = MathAtomFactory.latexSymbolName(for: atom) {
                        str += "\\\(command) "
                    } else {
                        str += "\(atom.nucleus)"
                    }
                }
                
                if atom.superScript != nil {
                    str += "^{\(MathAtomListToString(atom.superScript!))}"
                }
                
                if atom.subScript != nil {
                    str += "_{\(MathAtomListToString(atom.subScript!))}"
                }
            }
        }
        if currentfontStyle != .defaultStyle {
            str += "}"
        }
        return str
    }
    
    public static func delimToString(delim: MathAtom) -> String {
        if let command = MathAtomFactory.getDelimiterName(of: delim) {
            let singleChars = [ "(", ")", "[", "]", "<", ">", "|", ".", "/"]
            if singleChars.contains(command) {
                return command
            } else if command == "||" {
                return "\\|"
            } else {
                return "\\\(command)"
            }
        }
        return ""
    }
    
    mutating func atomForCommand(_ command:String) -> MathAtom? {
        if let atom = MathAtomFactory.atom(forLatexSymbol: command) {
            return atom
        }
        if let accent = MathAtomFactory.accent(withName: command) {
            // The command is an accent
            accent.innerList = self.buildInternal(true)
            return accent;
        } else if command == "frac" {
            // A fraction command has 2 arguments
            let frac = MathFraction()
            frac.numerator = self.buildInternal(true)
            frac.denominator = self.buildInternal(true)
            return frac;
        } else if command == "binom" {
            // A binom command has 2 arguments
            let frac = MathFraction(hasRule: false)
            frac.numerator = self.buildInternal(true)
            frac.denominator = self.buildInternal(true)
            frac.leftDelimiter = "(";
            frac.rightDelimiter = ")";
            return frac;
        } else if command == "sqrt" {
            // A sqrt command with one argument
            let rad = MathRadical()
            guard self.hasCharacters else {
                rad.radicand = self.buildInternal(true)
                return rad
            }
            let ch = self.getNextCharacter()
            if (ch == "[") {
                // special handling for sqrt[degree]{radicand}
                rad.degree = self.buildInternal(false, stopChar:"]")
                rad.radicand = self.buildInternal(true)
            } else {
                self.unlookCharacter()
                rad.radicand = self.buildInternal(true)
            }
            return rad;
        } else if command == "left" {
            // Save the current inner while a new one gets built.
            let oldInner = currentInnerAtom
            currentInnerAtom = MathInner()
            currentInnerAtom!.leftBoundary = self.getBoundaryAtom("left")
            if currentInnerAtom!.leftBoundary == nil {
                return nil;
            }
            currentInnerAtom!.innerList = self.buildInternal(false)
            if currentInnerAtom!.rightBoundary == nil {
                // A right node would have set the right boundary so we must be missing the right node.
                let errorMessage = "Missing \\right"
                self.setError(.missingRight, message:errorMessage)
                return nil
            }
            // reinstate the old inner atom.
            let newInner = currentInnerAtom;
            currentInnerAtom = oldInner;
            return newInner;
        } else if command == "overline" {
            // The overline command has 1 arguments
            let over = MathOverLine()
            over.innerList = self.buildInternal(true)
            return over
        } else if command == "underline" {
            // The underline command has 1 arguments
            let under = MathUnderLine()
            under.innerList = self.buildInternal(true)
            return under
        } else if command == "begin" {
            let env = self.readEnvironment()
            if env == nil {
                return nil;
            }
            let table = self.buildTable(env: env, firstList:nil, isRow:false)
            return table
        } else if command == "color" {
            // A color command has 2 arguments
            let mathColor = MathColor()
            mathColor.colorString = self.readColor()!
            mathColor.innerList = self.buildInternal(true)
            return mathColor
        } else if command == "textcolor" {
            // A textcolor command has 2 arguments
            let mathColor = MathTextColor()
            mathColor.colorString = self.readColor()!
            mathColor.innerList = self.buildInternal(true)
            return mathColor
        } else if command == "colorbox" {
            // A color command has 2 arguments
            let mathColorbox = MathColorBox()
            mathColorbox.colorString = self.readColor()!
            mathColorbox.innerList = self.buildInternal(true)
            return mathColorbox
        } else {
            let errorMessage = "Invalid command \\\(command)"
            self.setError(.invalidCommand, message:errorMessage)
            return nil;
        }
    }

    mutating func readColor() -> String? {
        if !self.expectCharacter("{") {
            // We didn't find an opening brace, so no env found.
            self.setError(.characterNotFound, message:"Missing {")
            return nil;
        }
        
        // Ignore spaces and nonascii.
        self.skipSpaces()
        
        // a string of all upper and lower case characters.
        var mutable = ""
        while self.hasCharacters {
            let ch = self.getNextCharacter()
            if ch == "#" || (ch >= "A" && ch <= "F") || (ch >= "a" && ch <= "f") || (ch >= "0" && ch <= "9") {
                mutable.append(ch)  // appendString:[NSString stringWithCharacters:&ch length:1]];
            } else {
                // we went too far
                self.unlookCharacter()
                break;
            }
        }
        
        if !self.expectCharacter("}") {
            // We didn't find an closing brace, so invalid format.
            self.setError(.characterNotFound, message:"Missing }")
            return nil;
        }
        return mutable;
    }

    mutating func skipSpaces() {
        while self.hasCharacters {
            let ch = self.getNextCharacter().utf32Char
            if ch < 0x21 || ch > 0x7E {
                // skip non ascii characters and spaces
                continue;
            } else {
                self.unlookCharacter()
                return;
            }
        }
    }
    
    static var fractionCommands: [String:[Character]] {
        [
            "over": [],
            "atop" : [],
            "choose" : [ "(", ")"],
            "brack" : [ "[", "]"],
            "brace" : [ "{", "}"]
        ]
    }
    
    mutating func stopCommand(_ command: String, list:MathAtomList, stopChar:Character?) -> MathAtomList? {
        if command == "right" {
            if currentInnerAtom == nil {
                let errorMessage = "Missing \\left";
                self.setError(.missingLeft, message:errorMessage)
                return nil;
            }
            currentInnerAtom!.rightBoundary = self.getBoundaryAtom("right")
            if currentInnerAtom!.rightBoundary == nil {
                return nil;
            }
            // return the list read so far.
            return list
        } else if let delims = Self.fractionCommands[command] {
            var frac:MathFraction! = nil;
            if command == "over" {
                frac = MathFraction()
            } else {
                frac = MathFraction(hasRule: false)
            }
            if delims.count == 2 {
                frac.leftDelimiter = String(delims[0])
                frac.rightDelimiter = String(delims[1])
            }
            frac.numerator = list;
            frac.denominator = self.buildInternal(false, stopChar: stopChar)
            if error != nil {
                return nil;
            }
            let fracList = MathAtomList()
            fracList.add(frac)
            return fracList
        } else if command == "\\" || command == "cr" {
            if currentEnv != nil {
                // Stop the current list and increment the row count
                currentEnv!.numRows+=1
                return list
            } else {
                // Create a new table with the current list and a default env
                if let table = self.buildTable(env: nil, firstList:list, isRow:true) {
                    return MathAtomList(atom: table)
                }
            }
        } else if command == "end" {
            if currentEnv == nil {
                let errorMessage = "Missing \\begin";
                self.setError(.missingBegin, message:errorMessage)
                return nil
            }
            let env = self.readEnvironment()
            if env == nil {
                return nil
            }
            if env! != currentEnv!.envName {
                let errorMessage = "Begin environment name \(currentEnv!.envName!) does not match end name: \(env!)"
                self.setError(.invalidEnv, message:errorMessage)
                return nil
            }
            // Finish the current environment.
            currentEnv!.ended = true
            return list
        }
        return nil
    }

    // Applies the modifier to the atom. Returns true if modifier applied.
    mutating func applyModifier(_ modifier:String, atom:MathAtom?) -> Bool {
        if modifier == "limits" {
            if atom?.type != .largeOperator {
                let errorMessage = "Limits can only be applied to an operator."
                self.setError(.invalidLimits, message:errorMessage)
            } else {
                let op = atom as! MathLargeOperator
                op.limits = true
            }
            return true
        } else if modifier == "nolimits" {
            if atom?.type != .largeOperator {
                let errorMessage = "No limits can only be applied to an operator."
                self.setError(.invalidLimits, message:errorMessage)
            } else {
                let op = atom as! MathLargeOperator
                op.limits = false
            }
            return true
        }
        return false
    }

    mutating func setError(_ code:MTParseErrors, message:String) {
        // Only record the first error.
        if error == nil {
            error = NSError(domain: MTParseError, code: code.rawValue, userInfo: [ NSLocalizedDescriptionKey : message ])
        }
    }
    
    mutating func atom(forCommand command: String) -> MathAtom? {
        if let atom = MathAtomFactory.atom(forLatexSymbol: command) {
            return atom
        }
        if let accent = MathAtomFactory.accent(withName: command) {
            accent.innerList = self.buildInternal(true)
            return accent
        } else if command == "frac" {
            let frac = MathFraction()
            frac.numerator = self.buildInternal(true)
            frac.denominator = self.buildInternal(true)
            return frac
        } else if command == "binom" {
            let frac = MathFraction(hasRule: false)
            frac.numerator = self.buildInternal(true)
            frac.denominator = self.buildInternal(true)
            frac.leftDelimiter = "("
            frac.rightDelimiter = ")"
            return frac
        } else if command == "sqrt" {
            let rad = MathRadical()
            let char = self.getNextCharacter()
            if char == "[" {
                rad.degree = self.buildInternal(false, stopChar: "]")
                rad.radicand = self.buildInternal(true)
            } else {
                self.unlookCharacter()
                rad.radicand = self.buildInternal(true)
            }
            return rad
        } else if command == "left" {
            let oldInner = self.currentInnerAtom
            self.currentInnerAtom = MathInner()
            self.currentInnerAtom?.leftBoundary = self.getBoundaryAtom("left")
            if self.currentInnerAtom?.leftBoundary == nil {
                return nil
            }
            self.currentInnerAtom!.innerList = self.buildInternal(false)
            if self.currentInnerAtom?.rightBoundary == nil {
                self.setError(.missingRight, message: "Missing \\right")
                return nil
            }
            let newInner = self.currentInnerAtom
            currentInnerAtom = oldInner
            return newInner
        } else if command == "overline" {
            let over = MathOverLine()
            over.innerList = self.buildInternal(true)
            
            return over
        } else if command == "underline" {
            let under = MathUnderLine()
            under.innerList = self.buildInternal(true)
            
            return under
        } else if command == "begin" {
            if let env = self.readEnvironment() {
                let table = self.buildTable(env: env, firstList: nil, isRow: false)
                return table
            } else {
                return nil
            }
        } else if command == "color" {
            // A color command has 2 arguments
            let mathColor = MathColor()
            mathColor.colorString = self.readColor()!
            mathColor.innerList = self.buildInternal(true)
            return mathColor
        } else if command == "colorbox" {
            // A color command has 2 arguments
            let mathColorbox = MathColorBox()
            mathColorbox.colorString = self.readColor()!
            mathColorbox.innerList = self.buildInternal(true)
            return mathColorbox
        } else {
            self.setError(.invalidCommand, message: "Invalid command \\\(command)")
            return nil
        }
    }
    
    mutating func readEnvironment() -> String? {
        if !self.expectCharacter("{") {
            // We didn't find an opening brace, so no env found.
            self.setError(.characterNotFound, message: "Missing {")
            return nil
        }
        
        self.skipSpaces()
        let env = self.readString()
        
        if !self.expectCharacter("}") {
            // We didn"t find an closing brace, so invalid format.
            self.setError(.characterNotFound, message: "Missing }")
            return nil;
        }
        return env
    }
    
    func MTAssertNotSpace(_ ch: Character) {
        assert(ch >= "\u{21}" && ch <= "\u{7E}", "Expected non-space character \(ch)")
    }
    
    mutating func buildTable(env: String?, firstList: MathAtomList?, isRow: Bool) -> MathAtom? {
        // Save the current env till an new one gets built.
        let oldEnv = self.currentEnv
        
        currentEnv = MTEnvProperties(name: env)
        
        var currentRow = 0
        var currentCol = 0
        
        var rows = [[MathAtomList]]()
        rows.append([MathAtomList]())
        if firstList != nil {
            rows[currentRow].append(firstList!)
            if isRow {
                currentEnv!.numRows+=1
                currentRow+=1
                rows.append([MathAtomList]())
            } else {
                currentCol+=1
            }
        }
        while !currentEnv!.ended && self.hasCharacters {
            let list = self.buildInternal(false)
            if list == nil {
                // If there is an error building the list, bail out early.
                return nil
            }
            rows[currentRow].append(list!)
            currentCol+=1
            if currentEnv!.numRows > currentRow {
                currentRow = currentEnv!.numRows
                rows.append([MathAtomList]())
                currentCol = 0
            }
        }
        
        if !currentEnv!.ended && currentEnv!.envName != nil {
            self.setError(.missingEnd, message: "Missing \\end")
            return nil
        }
        
        var error:NSError? = self.error
        let table = MathAtomFactory.table(withEnvironment: currentEnv?.envName, rows: rows, error: &error)
        if table == nil && self.error == nil {
            self.error = error
            return nil
        }
        self.currentEnv = oldEnv
        return table
    }
    
    mutating func getBoundaryAtom(_ delimiterType: String) -> MathAtom? {
        let delim = self.readDelimiter()
        if delim == nil {
            let errorMessage = "Missing delimiter for \\\(delimiterType)"
            self.setError(.missingDelimiter, message:errorMessage)
            return nil
        }
        let boundary = MathAtomFactory.boundary(forDelimiter: delim!)
        if boundary == nil {
            let errorMessage = "Invalid delimiter for \(delimiterType): \(delim!)"
            self.setError(.invalidDelimiter, message:errorMessage)
            return nil
        }
        return boundary
    }
    
    mutating func readDelimiter() -> String? {
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
        return nil
    }
    
    mutating func readCommand() -> String {
        let singleChars = "{}$#%_| ,>;!\\"
        if self.hasCharacters {
            let char = self.getNextCharacter()
            if let _ = singleChars.firstIndex(of: char)  {
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
