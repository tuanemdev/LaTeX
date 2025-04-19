# LaTeX for Swift

A native LaTeX rendering engine written in Swift that uses CoreText for high-quality typesetting without requiring MathJax or WebView.

## Features

- **Native Rendering**: Uses CoreText for efficient, high-quality rendering of mathematical expressions
- **Cross-Platform**: Supports all Apple platforms (iOS, iPadOS, macOS, tvOS, watchOS)
- **Framework Integration**: 
  - Works with UIKit via `MathLabel`
  - Works with SwiftUI via `MathView`
- **Customization Options**:
  - Multiple font families (Latin Modern, XITS, Garamond, Asana, etc.)
  - Custom text color and background
  - Adjustable font size
  - Display mode (inline or block)
  - Text alignment (left, center, right)
- **Rich Math Support**:
  - Fractions, radicals, and large operators
  - Subscripts and superscripts
  - Matrices and tables
  - Greek letters and mathematical symbols
  - Custom spacing
  - Color highlighting

## Installation

### Swift Package Manager

You can add LaTeX to your project using Swift Package Manager:

#### Using Xcode

1. Go to **File** > **Swift Packages** > **Add Package Dependency...**
2. Enter the package repository URL: `https://github.com/tuanemdev/LaTeX`
3. Select the version rule (branch, version, or commit)
4. Click **Next** and Xcode will integrate the package

#### Using Package.swift

Add the following to your `Package.swift` file's dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/tuanemdev/LaTeX", .upToNextMajor(from: "1.0.0"))
]
```

And then include it in your target dependencies:

```swift
targets: [
    .target(
        name: "YourTargetName",
        dependencies: ["LaTeX"]),
]
```

## Quick Start

### UIKit

```swift
let mathLabel = MathLabel()
mathLabel.mathFontSize = 20
mathLabel.latex = "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"
mathLabel.labelMode = .display
mathLabel.textAlignment = .center
view.addSubview(mathLabel)
```

### SwiftUI

```swift
struct ContentView: View {
    var body: some View {
        MathView(latex: "\\int_{0}^{\\infty} e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}")
    }
}
```

## Error Handling

The library provides built-in error handling with descriptive error messages when LaTeX expressions cannot be parsed.

```swift
mathLabel.displayErrorInline = true
```

## Performance

Designed for efficiency with minimal memory footprint and fast rendering, suitable for displaying multiple complex equations simultaneously.

## Requirements

- Swift 5.0+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- No external dependencies

## License

GNU v3 license
