# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **ppl.core**, the core compiler implementation for the PeoPl programming language. It's a Swift-based compiler toolchain that includes a parser, semantic analyzer, LLVM backend, and LSP server for editor integration.

## Build Commands

### Development Build
```bash
swift build
```

### Release Build (excludes development features like socket LSP server)
```bash
swift build -Xswiftc -DRELEASE -c release
```

### Run Tests
```bash
swift test
```

### Run Single Test
```bash
swift test --filter <TestClassName>/<testMethodName>
```

### Linting
The project uses SwiftLint with configuration in `.swiftlint.yml`. Run manually if needed:
```bash
swiftlint
```

## Compiler Commands

The main executable provides several subcommands:

### Parse and Print AST
```bash
swift run Main ast <file.ppl>
swift run Main ast <file.ppl> --errors-only  # Show only syntax errors
```

### Build Project (currently under development)
```bash
swift run Main build
swift run Main build --llvm --output output.ll
```

### Run LSP Server
```bash
swift run Main lsp
```

## Compilation Flags

The project uses conditional compilation flags defined in `Package.swift`:

- `TREE_SITTER_PARSER` - Enables Tree-sitter based parsing (currently active)
- `ANALYZER` - Enables semantic analysis phase (currently commented out)
- `LLVM_BACKEND` - Enables LLVM IR code generation (currently commented out)
- `RELEASE` - Production build configuration

When working on semantic analysis or LLVM backend code, you'll need to uncomment the relevant flags in `Package.swift`.

## Architecture

### Three-Phase Compilation Pipeline

1. **Frontend - Parsing** (`Sources/Main/FrontEnd/Parser/`)
   - Converts `.ppl` source files into Abstract Syntax Tree (AST)
   - Primary implementation: `TreeSitterModulParser` using Tree-sitter grammar from `../ppl.treesitter`
   - Core AST definition: `SyntaxTree.swift` defines all syntax nodes
   - Error handling: `SyntaxError.swift` for parse-time errors

2. **Frontend - Semantic Analysis** (`Sources/Main/FrontEnd/Analyzer/`)
   - Type checking and semantic validation (under `#if ANALYZER`)
   - `SemanticTree.swift` defines typed, validated IR
   - Multiple resolution passes organized as extensions on `SemanticTree`:
     - `SemanticTree+TypeSymbolResolution.swift` - Resolve type names
     - `SemanticTree+FunctionSymbolResolution.swift` - Resolve function signatures
     - `SemanticTree+ConstantsSymbolResolution.swift` - Resolve constants
     - `SemanticTree+GenericSymbolResolution.swift` - Generic type resolution
     - `SemanticTree+ExpressionTypeChecker.swift` - Expression type checking
     - `SemanticTree+BranchExhaustiveness.swift` - Pattern match exhaustiveness
   - Error handling: `SemanticError.swift`

3. **Backend - Code Generation** (`Sources/Main/Backend/LLVM/`)
   - LLVM IR generation (under `#if LLVM_BACKEND`)
   - Organized as extensions on LLVM builder:
     - `LLVM+Context.swift` - Module and context management
     - `LLVM+Types.swift` - Type translation to LLVM types
     - `LLVM+Functions.swift` - Function codegen
     - `LLVM+Expressions.swift` - Expression codegen

### LSP Integration

- **LSP Protocol Implementation** (`Sources/Lsp/`)
  - `Server.swift` - Generic LSP server implementation
  - `Rpc/` - JSON-RPC protocol messages (Common, Capabilities, DocumentSync, Diagnostic)
  - `Socket/` - TCP networking for LSP communication

- **PeoPl LSP Handler** (`Sources/Main/Lsp/`)
  - `Lsp.swift` - PeoPl-specific LSP handler that bridges parser/analyzer to LSP
  - `Lsp+Command.swift` - CLI command for running LSP server
  - Provides real-time diagnostics by parsing modules and running semantic checks

### Key Data Structures

**Syntax Tree (AST)** - Defined in `SyntaxTree.swift`:
- `Syntax.Project` - Root container mapping module names to modules
- `Syntax.Module` - Compilation unit (typically one `.ppl` file)
- `Syntax.Expression` - Core discriminated union for all expressions:
  - Literals, unary/binary operations, nominal references
  - Type definitions (product types via `TypeDefinition`)
  - Functions and lambdas
  - Calls, field access, bindings
  - Tagged expressions (for named parameters and sum types)
  - Branched expressions (pattern matching)
  - Piped expressions (function composition)
- `Syntax.QualifiedIdentifier` - Module-qualified names (e.g., `Module\SubModule\identifier`)
- `Syntax.NodeLocation` - Source location tracking for error reporting

**Semantic Tree (Typed IR)** - Defined in `SemanticTree.swift`:
- `Semantic.Expression` - Typed, validated expressions
- `Semantic.TypeSpecifier` - Type representations (intrinsic, record, choice, function)
- `Semantic.FunctionSignature` - Unique function identification by name + input type + arguments
- `Semantic.Pattern` - Pattern matching destructuring
- `Semantic.DecompositionMatrix` - Compiled pattern match branches

### Source Management

- `SourceManager.swift` - File discovery and loading
  - `readCurrentDirectory()` - Scans working directory for `.ppl` files
  - `readSingleFile(path:)` - Loads single file
  - Converts files to `Syntax.Source` objects for parsing

### Module System

Files are modules. The parser protocol `Syntax.ModuleParser` defines the interface:
```swift
protocol ModuleParser {
    static func parseModule(source: Source) -> Module
}
```

Current implementation is `TreeSitterModulParser` which uses the Tree-sitter grammar from `../ppl.treesitter`.

## Testing Strategy

Tests are in `Tests/MainTests/`:

- **Frontend Tests** (`FrontendTests/`)
  - Parser tests use `.ppl` files in `Resources/ParserTests/`
  - Semantic analysis tests (type resolution, type checking, etc.)
  - Test utilities in `Utils.swift` provide assertion helpers

- Test files follow naming: `parser_*.ppl` for parser tests

## Development Workflow

### Adding New Syntax Features

1. Update Tree-sitter grammar in `../ppl.treesitter`
2. Regenerate parser if needed
3. Add corresponding AST node to `SyntaxTree.swift`
4. Implement Tree-sitter → AST conversion in `SyntaxTree+TreeSitter.swift`
5. Add debug printing in `SyntaxTree+Debug.swift`
6. Create test file in `Tests/MainTests/Resources/ParserTests/`
7. Add test case using the `ast` command to verify parsing

### Adding Semantic Analysis

1. Ensure `ANALYZER` flag is enabled in `Package.swift`
2. Add type checking logic in appropriate `SemanticTree+*.swift` file
3. Update `SemanticTree.swift` if new semantic nodes needed
4. Add error cases to `SemanticError.swift`
5. Write tests in `Tests/MainTests/FrontendTests/`

### Adding LLVM Codegen

1. Ensure `LLVM_BACKEND` flag is enabled in `Package.swift`
2. Ensure LLVM is installed via Homebrew and in pkgconfig
3. Add codegen logic in appropriate `LLVM+*.swift` file
4. Test with `build` command

## Dependencies

- **SwiftTreeSitter** (0.9.0+) - Tree-sitter Swift bindings
- **ppl.treesitter** (local) - PeoPl language Tree-sitter grammar
- **swift-argument-parser** (1.0.0+) - CLI argument parsing
- **LLVM** (via Homebrew) - Code generation backend (when enabled)

## Code Style

SwiftLint configuration highlights:
- Line length: 80 warning, 100 error
- Function body length: 150 warning, 200 error
- File length: 1500 warning, 2000 error
- Cyclomatic complexity: 15 warning, 20 error
- Identifier names: 2-30 characters (single letter `i` allowed)
- Disabled rules: todo, trailing_comma, closure_parameter_position

## Language Design Notes

PeoPl is a functional language with:
- **Everything is a function** - Core design principle
- **Algebraic data types** - Product types (records) and sum types (tagged unions)
- **Pattern matching** - Via branched expressions with exhaustiveness checking
- **Qualified names** - Module system using `\` separator (e.g., `Module\Type`)
- **Named and unnamed arguments** - Tagged expressions for parameter naming
- **Pipe operator** - Function composition via piped expressions
- **Compile-time functions** - For generics and potential macro system

Special literals:
- `special` - Placeholder for partial application/currying
- `nothing` - Unit type `()`
- `never` - Bottom type for unreachable code
