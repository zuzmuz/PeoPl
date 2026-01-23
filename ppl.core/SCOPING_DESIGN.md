# Scoping and Symbol Resolution Design for PeoPl

## Core Concepts

### Element Hierarchy
Each semantic element has:
- **ElementId** - Unique identifier
- **Parent** - Parent scope ElementId
- **Symbol** - Qualified name (e.g., `Module\Type\field`)
- **Kind** - What kind of element (type, function, constant, field, binding)

```
Global (0)
├── Module "Main" (1)
│   ├── Type "Point" (2)
│   │   ├── Field [0] (3)
│   │   └── Field [1] (4)
│   ├── Type "Circle" (5)
│   │   ├── Field "center" (6)
│   │   └── Field "radius" (7)
│   └── Function "add" (8)
│       ├── Param "a" (9)
│       └── Param "b" (10)
└── Module "Geometry" (11)
    └── Type "Shape" (12)
```

### Symbol Table Structure

Two main data structures:

1. **Elements Array**: `[Element]`
   - Index is ElementId
   - Each element knows its parent, children, kind, location
   - Forms the scope hierarchy tree

2. **Symbol Lookup**: `[QualifiedIdentifier: ElementId]`
   - Maps fully qualified names to element IDs
   - E.g., `["Module", "Point"]` → ElementId(2)
   - E.g., `["Module", "Point", "0"]` → ElementId(3)

## Symbol Resolution Algorithm

### Unqualified Name Resolution
For a name like `Point` in some scope:
1. Check current scope's symbol table
2. If not found, check parent scope recursively
3. Stop at global scope

### Qualified Name Resolution
For a name like `Geometry\Shape`:
1. Parse into chain: `["Geometry", "Shape"]`
2. Start from global scope
3. Navigate: Global → Geometry module → Shape type
4. Direct lookup in symbol table

### Function Overload Resolution
Functions are special - same name, different signatures:
- Symbol table maps `(name, input_type, arg_names)` → Function
- Resolution requires type information
- Done in later phase after type resolution

## Three-Phase Semantic Analysis

### Phase 1: Symbol Collection
Walk the AST and build element hierarchy:
- Assign ElementId to each definition
- Build parent-child relationships
- Populate symbol lookup table
- Detect redeclarations

**Input**: `Syntax.Module` (AST)
**Output**:
- `elements: [Element]`
- `symbolTable: [QualifiedIdentifier: ElementId]`
- `errors: [SemanticError]` (redeclarations)

### Phase 2: Type Resolution
Resolve all type references:
- Convert `Syntax.Expression` type annotations to `TypeSpecifier`
- Resolve nominal types to their ElementIds
- Check for cyclic type definitions
- Infer types where possible

**Input**: Element hierarchy from Phase 1
**Output**:
- `typeInfo: [ElementId: TypeSpecifier]`
- `errors: [SemanticError]` (undefined types, cycles)

### Phase 3: Type Checking
Check expression types:
- Type check function bodies
- Type check operators
- Check pattern match exhaustiveness
- Check function calls

**Input**: Type-resolved elements from Phase 2
**Output**:
- Typed semantic tree
- `errors: [SemanticError]` (type mismatches, etc.)

## Example: Type Definition Scoping

```ppl
Point: [Float, Float]
Circle: [center' Point, radius' Float]
```

**Phase 1 - Symbol Collection:**
```
elements[2] = Element {
    id: 2,
    parent: 1 (Module),
    symbol: ["Module", "Point"],
    kind: .typeDefinition([3, 4])
}
elements[3] = Element {
    id: 3,
    parent: 2 (Point),
    symbol: ["Module", "Point", "0"],
    kind: .field(unnamed: 0)
}
elements[5] = Element {
    id: 5,
    parent: 1 (Module),
    symbol: ["Module", "Circle"],
    kind: .typeDefinition([6, 7])
}
elements[6] = Element {
    id: 6,
    parent: 5 (Circle),
    symbol: ["Module", "Circle", "center"],
    kind: .field(named: "center")
}

symbolTable = [
    ["Module", "Point"]: 2,
    ["Module", "Point", "0"]: 3,
    ["Module", "Point", "1"]: 4,
    ["Module", "Circle"]: 5,
    ["Module", "Circle", "center"]: 6,
    ["Module", "Circle", "radius"]: 7
]
```

**Phase 2 - Type Resolution:**
```
typeInfo[2] = .record([
    .unnamed(0): .nominal(["Float"]),  // resolved to intrinsic
    .unnamed(1): .nominal(["Float"])
])
typeInfo[5] = .record([
    .named("center"): .nominal(["Module", "Point"]),  // resolved to element 2
    .named("radius"): .nominal(["Float"])
])
```

## Implementation Strategy

Start with simplified version:
1. Only module-level definitions (no nested scopes yet)
2. Only types (defer functions and constants)
3. Only nominal type resolution (defer record/choice)
4. Build up complexity incrementally

This matches what the existing tests expect.
