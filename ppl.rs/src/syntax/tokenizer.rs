use logos::Logos;

#[derive(Logos, Clone, Debug, PartialEq)]
#[logos(skip r"[ \t]+")]
pub enum Token<'a> {
    // literals
    #[regex("[0-9][0-9_]*", |lex| lex.slice().parse::<u64>().ok())]
    DecLiteral(u64),
    #[regex("(0[x])[0-9a-zA-Z][0-9a-z-A-Z_]*", |lex|  u64::from_str_radix(&lex.slice()[2..], 16).ok() )]
    HexLiteral(u64),
    #[regex("(0[o])[0-7][0-7_]*", |lex| u64::from_str_radix(&lex.slice()[2..], 8).ok())]
    OctLiteral(u64),
    #[regex("(0[b])[01][01_]*", |lex| u64::from_str_radix(&lex.slice()[2..], 2).ok())]
    BinLiteral(u64),

    #[regex(r"([0-9][0-9_]*)*\.([0-9][0-9_]*)*([eE][+-]?[0-9_]+)?", |lex| lex.slice().parse::<f64>().ok())]
    FloatLiteral(f64),

    #[regex(r"((([0-9][0-9_]*)*\.([0-9][0-9_]*)*([eE][+-]?[0-9_]+)?)|([0-9][0-9_]*))i", |lex| {
        let slice = lex.slice();
        slice[0..(slice.len() - 1)].parse::<f64>().ok()
    })]
    ImaginaryLiteral(f64),

    #[regex(r#""([^"\\]|\\["\\bnfrt])*""#, |lex| {
        let slice = lex.slice();
        &slice[1..(slice.len()-1)]
    })]
    StringLiteral(&'a str),

    #[token("_")]
    Special, // underscore
    //
    // kwords
    #[token("if")]
    KwordIf,
    #[token("comp")]
    KwordComp,
    #[token("fn")]
    KwordFn,
    #[token("and")]
    KwordAnd,
    #[token("or")]
    KwordOr,
    #[token("not")]
    KwordNot,

    #[regex(r"\p{Alphabetic}[\p{Alphabetic}0-9_]*", |lex| lex.slice())]
    Identifier(&'a str),

    // arithmetics
    #[token("+")]
    OpPlus, // +
    #[token("-")]
    OpMinus, // -
    #[token("*")]
    OpTimes, // *
    #[token("/")]
    OpBy, // /
    #[token("%")]
    OpMod, // %
    #[token("^")]
    OpExponent, // ^

    // bitwise
    #[token("<<")]
    Lshift, // <<
    #[token(">>")]
    Rshift, // >>
    #[token(".&")]
    Band, // .&
    #[token(".|")]
    Bor, // .|
    #[token(".^")]
    Bxor, // .^
    #[token("~")]
    Bnot, // ~

    // access
    #[token(".", priority = 10)]
    Dot, // .
    #[token("|>")]
    Pipe, // |>
    #[token("?")]
    Propagate, // ?

    // comparisons
    #[token("=")]
    OpEq, // =
    #[token(">=")]
    OpGe, // >=
    #[token(">")]
    OpGt, // >
    #[token("<=")]
    OpLe, // <=
    #[token("<")]
    OpLt, // <

    // delimieters
    #[token("(")]
    Lparen, // (
    #[token(")")]
    Rparen, // )
    #[token("[")]
    Lbracket, // [
    #[token("]")]
    Rbracket, // ]
    #[token("{")]
    Lbrace, // {
    #[token("}")]
    Rbrace, // }

    // special
    #[token(",")]
    Comma, // ,
    #[token("|")]
    Bar, // |
    #[token("\\")]
    Backslash, // \
    #[token("'")]
    Appostrophe, // '
    #[token(":")]
    Colon, // :
    #[token("->")]
    Arrow, // ->
    #[regex(r"@\p{Alphabetic}[\p{Alphabetic}0-9_]*")]
    Binding, // @
    #[regex(r"\$[\p{Alphabetic}0-9_]+")]
    Positional, // $

    #[regex(r"//[.]*", priority = 20)]
    Comment,

    #[regex("\n|\r\n|\x0C")]
    NewLine,

    Eof,
}

pub fn lex_source<'a>(source: &'a str) -> Vec<Token<'a>> {
    let mut tokens: Vec<Token> = Token::lexer(source)
        .spanned()
        .filter_map(|(token, _)| token.ok())
        .collect();
    tokens.push(Token::Eof);
    tokens
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn numbers() {
        let test_string = "  12 0x8f  0b10_10_01_00   0o123_456 ";

        let mut lex = Token::lexer(test_string);
        let reference_tokens = [
            Token::DecLiteral(12),
            Token::HexLiteral(143),
            Token::BinLiteral(1),
            Token::OctLiteral(1),
            Token::Eof,
        ];

        for reference_token in reference_tokens {
            if let Some(Ok(token)) = lex.next() {
                assert_eq!(token, reference_token);
            } // else {
            //     assert!(false);
            // }
        }
    }

    #[test]
    fn function_def() {
        let test_string = "hey: fn [a: Int] -> { 3 }";
        let mut lex = Token::lexer(test_string);
        let reference_tokens = [
            Token::Identifier("hey"),
            Token::Colon,
            Token::KwordFn,
            Token::Lbracket,
            Token::Identifier("a"),
            Token::Colon,
            Token::Identifier("Int"),
            Token::Rbracket,
            Token::Arrow,
            Token::Lbrace,
            Token::DecLiteral(3),
            Token::Rbrace,
            Token::Eof,
        ];
        for reference_token in reference_tokens {
            if let Some(Ok(token)) = lex.next() {
                assert_eq!(token, reference_token);
            } // else {
            //     assert!(false);
            // }
        }
    }
}
