
# The good

- pattern matching
- sum types (enum, unions)
- product tupes (tuples)
- immutability
- object methods
- optional chaining
- named params
- implicit in field (if expression contains in field, it will automatically capture input)




# compilations step

- parsing
- syntax check (might need to migrate from treesitter)
    - generate syntax error list
- semantic check
    - resolve type declarations
        - resolve undefined types in type definitions
        - resolve circular dependencies in type definitions
    - resovle function declarations
        - resolve undefined types in function signature
    - type check expressions
    - verify function body inferred type with type signature

    - builtins and externals are treated separately
        - builtins can't be overriden
        - externals are automatically namespaced with module name

