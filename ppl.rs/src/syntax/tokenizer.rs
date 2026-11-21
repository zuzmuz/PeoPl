use logos::{Logos};

#[derive(Logos, Clone, Copy, Debug, PartialEq)]
#[logos(skip r"[ \t]+")]
pub enum Token<'a> {
    // literals
    #[regex("[0-9][0-9_]*", |lex| lex.slice().parse::<u64>().ok())]
    DecLiteral(u64),
    #[regex("(0[x])[0-9a-fA-F][0-9a-f-A-F_]*", |lex|  u64::from_str_radix(&lex.slice()[2..], 16).ok() )]
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
    Special,

    // kwords
    #[token("if")]
    KwordIf,
    #[token("comp")]
    KwordComp,
    #[token("fn")]
    KwordFn,
    #[regex("[ \t\n\r\n\x0c]*and")]
    KwordAnd,
    #[regex("[ \t\n\r\n\x0c]*or")]
    KwordOr,
    #[token("not")]
    KwordNot,

    #[regex(r"[\p{XID_Start}][\p{XID_Continue}\p{So}\p{Sk}]*", |lex| lex.slice())]
    Identifier(&'a str),

    // arithmetics
    #[regex("[ \t\n\r\n\x0c]*\\+")]
    OpPlus,
    #[regex("[ \t\n\r\n\x0c]*-")]
    OpMinus,
    #[regex("[ \t\n\r\n\x0c]*\\*")]
    OpTimes,
    #[regex("[ \t\n\r\n\x0c]*/")]
    OpBy,
    #[regex("[ \t\n\r\n\x0c]*%")]
    OpMod,
    #[regex("[ \t\n\r\n\x0c]*\\^")]
    OpExponent,

    // bitwise
    #[regex("[ \t\n\r\n\x0c]*<<")]
    Lshift,
    #[regex("[ \t\n\r\n\x0c]*>>")]
    Rshift,
    #[regex("[ \t\n\r\n\x0c]*\\.&", priority=100)]
    Band,
    #[regex("[ \t\n\r\n\x0c]*\\.\\|", priority=100)]
    Bor,
    #[regex("[ \t\n\r\n\x0c]*\\.\\^", priority=100)]
    Bxor,
    #[token("~", priority=100)]
    Bnot,

    // access
    #[regex("[ \t\n\r\n\x0c]*\\.", priority = 10)]
    Dot,
    #[regex("[ \t\n\r\n\x0c]*\\|>")]
    Pipe,
    #[regex("[ \t\n\r\n\x0c]*\\?")]
    Propagate,

    // comparisons
    #[regex("[ \t\n\r\n\x0c]*=")]
    OpEq,
    #[regex("[ \t\n\r\n\x0c]*>=")]
    OpGe,
    #[regex("[ \t\n\r\n\x0c]*>")]
    OpGt,
    #[regex("[ \t\n\r\n\x0c]*<=")]
    OpLe,
    #[regex("[ \t\n\r\n\x0c]*<")]
    OpLt,

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
    #[regex("[ \t\n\r\n\x0c]*->")]
    Arrow, // ->

    #[regex(r"@[\p{XID_Start}][\p{XID_Continue}\p{So}\p{Sk}]*", |lex| &lex.slice()[1..])]
    Binding(&'a str), // @
    #[regex(r"\$[\p{XID_Start}][\p{XID_Continue}\p{So}\p{Sk}]*", |lex| &lex.slice()[1..])]
    PositionalStr(&'a str), // $
    #[regex(r"\$[0-9][0-9_]*", |lex| lex.slice()[1..].parse::<u64>().ok())]
    PositionalInt(u64), // $

    #[regex(r"//.*", allow_greedy = true)]
    Comment,

    #[regex("(\n|\r\n|\x0C)[ \t\n\r\n\x0C]*")]
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
    fn unicode_identifiers() {
        let test_string = "factor🫶🏽sdf π résumé";
        let mut lex = Token::lexer(test_string);
        assert_eq!(lex.next(), Some(Ok(Token::Identifier("factor🫶🏽sdf"))));
        assert_eq!(lex.next(), Some(Ok(Token::Identifier("π"))));
        assert_eq!(lex.next(), Some(Ok(Token::Identifier("résumé"))));
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
