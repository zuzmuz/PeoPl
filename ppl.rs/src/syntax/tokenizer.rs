use logos::{Lexer, Logos};

#[derive(Logos, Clone, Debug, PartialEq, Eq)]
#[logos(skip r"[ \t]+")]
pub enum TokenKind {
    // literals
    #[regex("[0-9][0-9_]*", priority = 10)]
    DecLiteral,
    #[regex("(0[x])[0-9a-zA-Z][0-9a-z-A-Z_]*", priority = 10)]
    HexLiteral,
    #[regex("(0[o])[0-7][0-7_]*", priority = 10)]
    OctLiteral,
    #[regex("(0[b])[01][01_]*", priority = 10)]
    BinLiteral,

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

    Eof,
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

        while let Some(tok) = lex.next() {
            println!("{:?}  {:?}", tok, lex.slice());
            //        ^token      ^source text it matched
        }
    }
}
