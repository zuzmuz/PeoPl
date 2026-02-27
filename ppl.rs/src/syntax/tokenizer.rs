use logos::{Lexer, Logos};

#[derive(Logos, Clone, Debug, PartialEq, Eq)]
#[logos(skip r"[ \t]+")]
pub enum TokenKind {
    // literals
    #[regex("[0-9][0-9_]*", |lex| lex.slice().parse::<u64>().ok())]
    DecLiteral(u64),
    #[regex("(0[x])[0-9a-zA-Z][0-9a-z-A-Z_]*", |lex| lex.slice().parse::<u64>().ok())]
    HexLiteral(u64),
    #[regex("(0[o])[0-7][0-7_]*", |lex| lex.slice().parse::<u64>().ok())]
    OctLiteral(u64),
    #[regex("(0[b])[01][01_]*", |lex| lex.slice().parse::<u64>().ok())]
    BinLiteral(u64),

    #[regex(r"([0-9][0-9_]*)*\.([0-9][0-9_]*)*([eE][+-]?[0-9_]+)?")]
    FloatLiteral,
    #[regex(r"([0-9][0-9_]*)*\.([0-9][0-9_]*)*([eE][+-]?[0-9_]+)?i")]
    ImaginaryLiteral,
    #[regex(r#""([^"\\]|\\["\\bnfrt])*""#)]
    StringLiteral,

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

    #[regex(r"\p{Alphabetic}[\p{Alphabetic}0-9_]*")]
    Identifier,

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
}

pub fn lex_source(source: &str) {
    let mut lex = TokenKind::lexer(source);

    while let Some(tok) = lex.next() {
        println!("{:?}  {:?}", tok, lex.slice());
        //        ^token      ^source text it matched
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn numbers() {
        let test_string = "  12 0x8f  0b10_10_01_00   0o123_456 ";

        let mut lex = TokenKind::lexer(test_string);
        let reference_tokens = [
            TokenKind::DecLiteral(12),
            TokenKind::HexLiteral(143),
            TokenKind::BinLiteral(1),
            TokenKind::OctLiteral(1),
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
        let mut lex = TokenKind::lexer(test_string);
        let reference_tokens = [
            TokenKind::Identifier,
            TokenKind::Colon,
            TokenKind::KwordFn,
            TokenKind::Lbracket,
            TokenKind::Identifier,
            TokenKind::Colon,
            TokenKind::Identifier,
            TokenKind::Rbracket,
            TokenKind::Arrow,
            TokenKind::Lbrace,
            TokenKind::DecLiteral(3),
            TokenKind::Rbrace,
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
