use phf::phf_map;

#[derive(Clone)]
enum TokenKind {
    // literals
    IntLiteral,
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

#[derive(Clone)]
struct Point {
    line: usize,
    column: usize,
}

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
                [self.next_cursor..self.next_cursor + 4]
                .chars()
                .next()
                .unwrap_or('\0');
            if self.current_rune == '\n' {
                self.end.line += 1;
                self.end.column = 0;
            } else {
                self.end.column += self.current_rune.len_utf8();
            }
        } else {
            self.next_rune = '\0';
            if self.current_rune == '\n' {
                self.end.line += 1;
                self.end.column = 0;
            } else if self.current_rune != '\0' {
                self.end.column += self.current_rune.len_utf8();
            }
        }
    }

    fn skip_spaces(&mut self) {
        loop {
            match self.next_rune {
                ' ' | '\t' | '\r' => self.advance(),
                _ => break,
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
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        // let result = add(2, 2);
        // assert_eq!(result, 4);
    }
}
