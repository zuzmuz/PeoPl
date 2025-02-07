
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
- semantic check
    - make sure declarations are valid (do duplicates)
    - validate implementations (for nominal implementations statements)
    - type checking on expressions
- constants evaluation
