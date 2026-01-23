pub const TokenType = enum {
    // literals
    int_literal, // decimal, hexadecimal, octal, binary
    float_literal, 
    string_literal,
    // true_literal,
    // false_literal,
    special, // underscore

    // kwords
    kword_if,
    kword_comp,
    kword_fn,
    kword_and,
    kword_or,
    kword_not,

    // arithmetics
    plus, // +
    minus, // -
    times, // *
    by, // /
    mod, // %
    exponent, // ^

    // bitwise
    lshift, // <<
    rshift, // >>
    band, // .&
    bor, // .|
    bxor, // .^
    bnot, // ~

    // access
    dot, // .
    pipe, // |>
    propagate, // ?

    // comparisons
    eq, // =
    ge, // >=
    gt, // >
    le, // <=
    lt, // <

    // delimieters
    lparen, // (
    rparen, // )
    lbracket, // [
    rbracket, // ]
    lbrace, // {
    rbrace, // }

    // special
    comma, // delimiting expressions
    bar, // for capture blocks
    backslash, // for qualified identifiers
    appostrophe, // for type definitions
    arrow, // ->
    binding, // @
    positional, // $

    eof,
    invalid
};
