use std::io::{Write, stdout};

use phf::phf_map;

#[derive(Clone, Debug, PartialEq, Eq)]
enum TokenKind {
    // literals
    DecLiteral,
    HexLiteral,
    OctLiteral,
    BinLiteral,
    FloatLiteral,
    ImaginaryLiteral,
    StringLiteral,
    Identifier,
    Special, // underscore

    // kwords
    KwordIf,
    KwordComp,
    KwordFn,
    KwordAnd,
    KwordOr,
    KwordNot,

    // arithmetics
    OpPlus,     // +
    OpMinus,    // -
    OpTimes,    // *
    OpBy,       // /
    OpMod,      // %
    OpExponent, // ^

    // bitwise
    Lshift, // <<
    Rshift, // >>
    Band,   // .&
    Bor,    // .|
    Bxor,   // .^
    Bnot,   // ~

    // access
    Dot,       // .
    Pipe,      // |>
    Propagate, // ?

    // comparisons
    OpEq, // =
    OpGe, // >=
    OpGt, // >
    OpLe, // <=
    OpLt, // <

    // delimieters
    Lparen,   // (
    Rparen,   // )
    Lbracket, // [
    Rbracket, // ]
    Lbrace,   // {
    Rbrace,   // }

    // special
    Comma,       // delimiting expressions
    Bar,         // for capture blocks
    Backslash,   // for qualified identifiers
    Appostrophe, // for type definitions
    Colon,       // for expression definitions
    Arrow,       // ->
    Binding,     // @
    Positional,  // $

    Comment,
    NewLine,

    Eof,
    Invalid,
}

fn is_utf8(c: u8) -> bool {
    return (c & 0x80) != 0;
}

static KEYWORDS: phf::Map<&'static str, TokenKind> = phf_map! {
    "and" => TokenKind::KwordAnd,
    "or" => TokenKind::KwordOr,
    "not" => TokenKind::KwordNot,
};

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
struct Point {
    line: usize,
    column: usize,
}

#[derive(Debug, PartialEq, Eq)]
struct Token<'a> {
    kind: TokenKind,
    value: &'a str,
    start: Point,
    end: Point,
}

struct Tokenizer<'a> {
    source: &'a str,

    start_of_token: usize,
    next_cursor: usize,
    current_cursor: usize,
    next_rune: char,
    current_rune: char,

    start: Point,
    end: Point,
}

impl<'a> Tokenizer<'a> {
    pub fn new(source: &'a str) -> Self {
        let mut init_value = Self {
            source,
            start_of_token: 0,
            next_cursor: 0,
            current_cursor: 0,
            next_rune: '\0',
            current_rune: '\0',
            start: Point { line: 0, column: 0 },
            end: Point { line: 0, column: 0 },
        };
        init_value.advance();
        return init_value;
    }

    pub fn next_token(&mut self) -> Token<'a> {
        self.skip_spaces();

        self.start_of_token = self.current_cursor;
        self.start = self.end.clone();

        self.advance();

        match self.current_rune {
            '\n' => self.generate_token(TokenKind::NewLine),
            r if r.is_digit(10) => self.consume_number(),
            // r if r.is_alphabetic() => self.consume_identifier(),
            _ => self.generate_token(TokenKind::Invalid),
        }
    }

    fn generate_token(&self, kind: TokenKind) -> Token<'a> {
        return Token {
            kind: kind,
            value: &self.source
                [self.start_of_token..self.current_cursor],
            start: self.start.clone(),
            end: self.end.clone(),
        };
    }

    fn advance(&mut self) {
        self.current_rune = self.next_rune;
        self.current_cursor = self.next_cursor;

        if self.next_cursor < self.source.len() {
            self.next_rune = self.source
                [self.next_cursor..(self.next_cursor + 4).min(self.source.len())]
                .chars()
                .next()
                .unwrap_or('\0');
            self.next_cursor += self.current_rune.len_utf8();
        } else {
            self.next_rune = '\0';
        }

        if self.current_rune == '\n' {
            self.end.line += 1;
            self.end.column = 0;
        } else if self.current_rune != '\0' {
            self.end.column += self.current_rune.len_utf8();
        }

        println!(
            "here is the current and next runes {}, {}",
            self.current_rune, self.next_rune
        );
    }

    fn skip_spaces(&mut self) {
        let mut i = 0;
        loop {
            match self.next_rune {
                ' ' | '\t' | '\r' => self.advance(),
                _ => break,
            }
            i += 1;
            if i == 10 {
                break;
            }
        }
    }

    fn consume_identier(&mut self) -> Token<'a> {
        while self.next_rune.is_alphanumeric() {
            self.advance();
        }
        let identifier_value =
            &self.source[self.start_of_token..self.current_cursor];
        if let Some(token_kind) = KEYWORDS.get(identifier_value) {
            self.generate_token(token_kind.to_owned())
        } else {
            self.generate_token(TokenKind::Identifier)
        }
    }

    fn consume_number(&mut self) -> Token<'a> {
        if self.current_rune == '0' {
            self.advance();
            match self.current_rune {
                'b' => {
                    while self.next_rune.is_digit(2)
                        || self.next_rune == '_'
                    {
                        self.advance();
                    }
                    self.generate_token(TokenKind::BinLiteral)
                }
                'o' => {
                    while self.next_rune.is_digit(8)
                        || self.next_rune == '_'
                    {
                        self.advance();
                    }
                    self.generate_token(TokenKind::OctLiteral)
                }
                'x' => {
                    while self.next_rune.is_digit(16)
                        || self.next_rune == '_'
                    {
                        self.advance();
                    }
                    self.generate_token(TokenKind::HexLiteral)
                }
                _ => self.generate_token(TokenKind::Invalid),
            }
        } else {
            while self.next_rune.is_digit(10) {
                self.advance();
            }
            self.generate_token(TokenKind::DecLiteral)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn numbers() {
        let test_string = "  12 0x8f  0b10_10_01_00   0o123_456 ";

        let mut tokenizer = Tokenizer::new(test_string);

        let reference_tokens = [
            Token {
                kind: TokenKind::DecLiteral,
                value: &test_string[2..4],
                start: Point { line: 0, column: 2 },
                end: Point { line: 0, column: 4 },
            },
            Token {
                kind: TokenKind::HexLiteral,
                value: &test_string[5..9],
                start: Point { line: 0, column: 5 },
                end: Point { line: 0, column: 9 },
            },
            Token {
                kind: TokenKind::BinLiteral,
                value: &test_string[11..24],
                start: Point {
                    line: 0,
                    column: 11,
                },
                end: Point {
                    line: 0,
                    column: 24,
                },
            },
            Token {
                kind: TokenKind::OctLiteral,
                value: &test_string[27..36],
                start: Point {
                    line: 0,
                    column: 27,
                },
                end: Point {
                    line: 0,
                    column: 36,
                },
            },
        ];

        for reference_token in reference_tokens {
            let token = tokenizer.next_token();
            assert_eq!(reference_token, token);
        }
        // let result = add(2, 2);
        // assert_eq!(result, 4);
    }
}
