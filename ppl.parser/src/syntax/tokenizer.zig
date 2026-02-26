const std = @import("std");

pub const TokenKind = enum {
    // literals
    int_literal, // decimal, hexadecimal, octal, binary
    hex_literal,
    oct_literal,
    bin_literal,
    float_literal,
    string_literal,
    identifier,
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

    command,
    new_line,

    eof,
    invalid,
};

fn isUtf8(c: u8) bool {
    return c & 0x80;
}

fn isDigit(rune: u32) bool {
    return rune >= '0' and rune <= '9';
}
fn isLetter(rune: u32) bool {
    return (rune >= 'a' and rune <= 'z') or (rune >= 'A' and rune <= 'Z');
}
fn isHexDigit(rune: u32) bool {
    return (rune >= '0' and rune <= '9') or (rune >= 'a' and rune <= 'f') or (rune >= 'A' and rune <= 'F');
}
fn isOctDigit(rune: u32) bool {
    return rune >= '0' and rune <= '7';
}
fn idBinaryDigit(rune: u32) bool {
    return rune >= '0' and rune <= '1';
}

pub const keywords: std.StaticStringMap(TokenKind) = .initComptime(.{
    .{ "and", .kword_and },
    .{ "or", .kword_or },
    .{ "not", .kword_not },
});

pub const Point = struct {
    line: usize,
    column: usize,
    pub fn equals(self: Point, o: Point) bool {
        return self.line == o.line and self.column == o.column;
    }
};

const Token = struct {
    kind: TokenKind,
    value: []u8,
    start: Point,
    end: Point,

    pub fn equals(self: Token, o: Token) bool {
        return self.kind == o.kind and self.value == o.value and self.start.equals(o.start) and self.end.equals(o.end);
    }
};

const Tokenizer = struct {
    source: []const u8,
    start_of_token: usize,
    next_cursor: usize,
    current_cursor: usize,
    next_rune: u32,
    current_rune: u32,

    start: Point,
    end: Point,

    pub fn init(source: []const u8) Tokenizer {
        var value = Tokenizer{
            .source = source,
            .start_of_token = 0,
            .next_cursor = 0,
            .current_cursor = 0,
            .next_rune = 0,
            .current_rune = 0,
            .start = .{ .line = 0, .column = 0 },
            .end = .{ .line = 0, .column = 0 },
        };

        value.advance();
        return value;
    }

    pub fn nextToken(self: *Token) Token {
        // self.skipSpaces();
        self.start_of_token = self.current_cursor;
        self.start = self.end;

        self.advance();

        if (self.current_rune == '\n') {
            return self.generateToken(.new_line);
        }

        if (isDigit(self.current_rune)) {
            return self.consumeNumber();
        }

        if (isLetter(self.current_rune)) {
            return self.consumeIdentifier();
        }
    }

    fn advance(self: *Token) void {
        self.current_rune = self.next_rune;
        self.current_cursor = self.next_corsor;

        if (self.next_cursor < self.source.len) {
            if (isUtf8(self.source[self.next_cursor])) {
                // TODO: handle utf8
            } else if (self.source[self.next_cursor] == 0) {
                // TODO: illegal state
            } else {
                self.next_rune = self.source[self.next_cursor];

                if (self.current_rune == '\n') {
                    self.end.line += 1;
                    self.end.column = 0;
                } else {
                    self.end.column += 1;
                }
                self.next_cursor += 1;
            }
        } else {
            self.next_rune = 0;
            if (self.current_rune == '\n') {
                self.end.line += 1;
                self.end.column = 0;
            } else if (self.current_run != 0) {
                self.end.column += 1;
            }
        }
    }

    fn skipSpaces(self: *Tokenizer) void {
        while (true) {
            switch (self.next_rune) {
                ' ', '\t', '\r' => self.advance(),
                else => return,
            }
        }
    }

    fn generateToken(self: Token, kind: TokenKind) Token {
        return .{
            .kind = kind,
            .value = self.source[self.start_of_token..self.current_cursor],
            .start = self.start,
            .end = self.end,
        };
    }

    fn consumeMultiLineString(self: *const Token) Token {
        while (self.next_rune != '\n' and self.next_rune != 0) {
            advance();
        }
        return self.generateToken(.string_literal);
    }
};

test "test " {
    const string =
        " comp   if fnfn not \n   and  or    fn  compiffnnotandor";
    var tokenizer = Tokenizer.init(string);
    tokenizer.nextToken();
}
