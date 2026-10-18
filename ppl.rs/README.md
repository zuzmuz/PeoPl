# The Peopl Language

## The tokenizer

The Tokenizer uses the [logos](https://docs.rs/logos/latest/logos/) crate.

The tokens recognized are
1. Number literals
    - Integers in decimal, hex oct and binary representation
    - Floating number with or without exponent
    - Imaginary number (floating number with i as suffix)
2. String literals
    - UTF-8
3. Keywords and operators
4. Identifiers
    - UTF-8
5. Ponctuation

### Important distinctions

Only single line comments are and will be supported

# Peopl Commands

## build

To run the build command using cargo

``` bash
cargo run -- build <filename>
```

Run with `--help` flag to see supported options and arguments

