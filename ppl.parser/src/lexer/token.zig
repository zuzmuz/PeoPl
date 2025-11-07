pub const TokenType = enum {
    // literals
    number,
    string,
    identifier,
    true_literal,
    false_literal,
    nothing,
    underscore,

    // kwords
    kword_if,
    kword_fn,
    kword_and,
    kword_or,
    kword_not,

    // arithmetics
    plus,
    minus,
    star,
    slash,
    percent,

    // access
    dot,
    pipe,
    optional_pipe,

    // comparisons
    equal,
    ge,
    gt,
    le,
    lt,

    // delimieters
    lparen,
    rparen,
    lbracket,
    rbracket,
    lbrace,
    rbrace,

    // special
    colon,
    comma,
    bar,
    dollar,
    backslash,
    arrow,

    eof,
    invalid
};
