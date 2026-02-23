const std = @import("std");
const token = @import("token.zig");

pub const Token = struct {
    type: token.TokenType,
    lexeme: []const u8,
    line: usize,
    column: usize,
};

pub const Lexer = struct {
    source: []const u8,
    start: usize = 0,
    current: usize = 0,
    line: usize = 1,
    column: usize = 1,
    start_column: usize = 1,

    const Self = @This();

    pub fn init(source: []const u8) Self {
        return .{
            .source = source,
        };
    }

    pub fn nextToken(self: *Self) Token {
        self.skipWhitespace();

        self.start = self.current;
        self.start_column = self.column;

        if (self.isAtEnd()) {
            return self.makeToken(.eof);
        }

        const c = self.advance();

        // Handle identifiers and keywords
        if (isAlpha(c)) {
            return self.identifier();
        }

        // Handle numeric literals
        if (isDigit(c)) {
            return self.number();
        }

        // Handle operators and punctuation
        return switch (c) {
            // Single character tokens
            '+' => self.makeToken(.plus),
            '*' => self.makeToken(.times),
            '/' => self.makeToken(.by),
            '%' => self.makeToken(.mod),
            '^' => self.makeToken(.exponent),
            '~' => self.makeToken(.bnot),
            '(' => self.makeToken(.lparen),
            ')' => self.makeToken(.rparen),
            '[' => self.makeToken(.lbracket),
            ']' => self.makeToken(.rbracket),
            '{' => self.makeToken(.lbrace),
            '}' => self.makeToken(.rbrace),
            ',' => self.makeToken(.comma),
            '\\' => self.makeToken(.backslash),
            '\'' => self.makeToken(.appostrophe),
            '@' => self.makeToken(.binding),
            '$' => self.makeToken(.positional),
            '_' => self.makeToken(.special),

            // Multi-character possibilities
            '-' => if (self.match('>')) self.makeToken(.arrow) else self.makeToken(.minus),
            '=' => self.makeToken(.eq),
            '>' => if (self.match('='))
                self.makeToken(.ge)
            else if (self.match('>'))
                self.makeToken(.rshift)
            else
                self.makeToken(.gt),
            '<' => if (self.match('='))
                self.makeToken(.le)
            else if (self.match('<'))
                self.makeToken(.lshift)
            else
                self.makeToken(.lt),

            // Dot-based operators
            '.' => if (self.match('&'))
                self.makeToken(.band)
            else if (self.match('|'))
                self.makeToken(.bor)
            else if (self.match('^'))
                self.makeToken(.bxor)
            else
                self.makeToken(.dot),

            // Pipe-based operators
            '|' => if (self.match('>')) self.makeToken(.pipe) else self.makeToken(.bar),

            // Question mark
            '?' => self.makeToken(.propagate),

            // String literals
            '"' => self.string(),

            else => self.makeToken(.invalid),
        };
    }

    fn isAtEnd(self: *const Self) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Self) u8 {
        const c = self.source[self.current];
        self.current += 1;
        self.column += 1;
        return c;
    }

    fn peek(self: *const Self) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *const Self) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn match(self: *Self, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;
        self.current += 1;
        self.column += 1;
        return true;
    }

    fn skipWhitespace(self: *Self) void {
        while (!self.isAtEnd()) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = self.advance();
                },
                '\n' => {
                    self.line += 1;
                    self.column = 0;
                    _ = self.advance();
                },
                '/' => {
                    // Check for comments
                    if (self.peekNext() == '/') {
                        // Single-line comment
                        while (self.peek() != '\n' and !self.isAtEnd()) {
                            _ = self.advance();
                        }
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }

    fn string(self: *Self) Token {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') {
                self.line += 1;
                self.column = 0;
            }
            // Handle escape sequences
            if (self.peek() == '\\') {
                _ = self.advance(); // Skip the backslash
                if (!self.isAtEnd()) {
                    _ = self.advance(); // Skip the escaped character
                }
            } else {
                _ = self.advance();
            }
        }

        if (self.isAtEnd()) {
            return self.makeToken(.invalid);
        }

        // Consume closing quote
        _ = self.advance();
        return self.makeToken(.string_literal);
    }

    fn number(self: *Self) Token {
        // Check for hexadecimal
        if (self.source[self.start] == '0' and !self.isAtEnd()) {
            const next = self.peek();
            if (next == 'x' or next == 'X') {
                _ = self.advance();
                while (isHexDigit(self.peek())) {
                    _ = self.advance();
                }
                return self.makeToken(.int_literal);
            } else if (next == 'b' or next == 'B') {
                // Binary
                _ = self.advance();
                while (self.peek() == '0' or self.peek() == '1') {
                    _ = self.advance();
                }
                return self.makeToken(.int_literal);
            } else if (next == 'o' or next == 'O') {
                // Octal
                _ = self.advance();
                while (self.peek() >= '0' and self.peek() <= '7') {
                    _ = self.advance();
                }
                return self.makeToken(.int_literal);
            }
        }

        // Regular decimal number
        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        // Check for decimal point
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            // Consume the dot
            _ = self.advance();

            while (isDigit(self.peek())) {
                _ = self.advance();
            }

            // Check for exponent
            if (self.peek() == 'e' or self.peek() == 'E') {
                _ = self.advance();
                if (self.peek() == '+' or self.peek() == '-') {
                    _ = self.advance();
                }
                while (isDigit(self.peek())) {
                    _ = self.advance();
                }
            }

            return self.makeToken(.float_literal);
        }

        return self.makeToken(.int_literal);
    }

    fn identifier(self: *Self) Token {
        while (isAlphaNumeric(self.peek())) {
            _ = self.advance();
        }

        const text = self.source[self.start..self.current];
        const token_type = identifierType(text);
        return self.makeToken(token_type);
    }

    fn identifierType(text: []const u8) token.TokenType {
        // Simple keyword matching
        const keywords = .{
            .{ "if", token.TokenType.kword_if },
            .{ "comp", token.TokenType.kword_comp },
            .{ "fn", token.TokenType.kword_fn },
            .{ "and", token.TokenType.kword_and },
            .{ "or", token.TokenType.kword_or },
            .{ "not", token.TokenType.kword_not },
        };

        inline for (keywords) |kw| {
            if (std.mem.eql(u8, text, kw[0])) {
                return kw[1];
            }
        }

        return .identifier;
    }

    fn makeToken(self: *const Self, token_type: token.TokenType) Token {
        return .{
            .type = token_type,
            .lexeme = self.source[self.start..self.current],
            .line = self.line,
            .column = self.start_column,
        };
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isHexDigit(c: u8) bool {
        return isDigit(c) or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
    }

    fn isAlpha(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }

    fn isAlphaNumeric(c: u8) bool {
        return isAlpha(c) or isDigit(c);
    }
};

// Test the lexer
test "lexer basic tokens" {
    const source = "+ - * / % ^";
    var lexer = Lexer.init(source);

    const expected = [_]token.TokenType{ .plus, .minus, .times, .by, .mod, .exponent, .eof };

    for (expected) |expected_type| {
        const tok = lexer.nextToken();
        try std.testing.expectEqual(expected_type, tok.type);
    }
}

test "lexer keywords" {
    const source = "if fn comp and or not";
    var lexer = Lexer.init(source);

    const expected = [_]token.TokenType{ .kword_if, .kword_fn, .kword_comp, .kword_and, .kword_or, .kword_not, .eof };

    for (expected) |expected_type| {
        const tok = lexer.nextToken();
        try std.testing.expectEqual(expected_type, tok.type);
    }
}

test "lexer numbers" {
    const source = "42 3.14 0xFF 0b101 0o77";
    var lexer = Lexer.init(source);

    try std.testing.expectEqual(token.TokenType.int_literal, lexer.nextToken().type);
    try std.testing.expectEqual(token.TokenType.float_literal, lexer.nextToken().type);
    try std.testing.expectEqual(token.TokenType.int_literal, lexer.nextToken().type);
    try std.testing.expectEqual(token.TokenType.int_literal, lexer.nextToken().type);
    try std.testing.expectEqual(token.TokenType.int_literal, lexer.nextToken().type);
}

test "lexer strings" {
    const source = "\"hello world\" \"escaped\\\"quote\"";
    var lexer = Lexer.init(source);

    const tok1 = lexer.nextToken();
    try std.testing.expectEqual(token.TokenType.string_literal, tok1.type);
    try std.testing.expectEqualStrings("\"hello world\"", tok1.lexeme);

    const tok2 = lexer.nextToken();
    try std.testing.expectEqual(token.TokenType.string_literal, tok2.type);
}

test "lexer multi-character operators" {
    const source = "-> >= <= << >> .& .| .^ |>";
    var lexer = Lexer.init(source);

    const expected = [_]token.TokenType{ .arrow, .ge, .le, .lshift, .rshift, .band, .bor, .bxor, .pipe, .eof };

    for (expected) |expected_type| {
        const tok = lexer.nextToken();
        try std.testing.expectEqual(expected_type, tok.type);
    }
}

test "lexer delimiters" {
    const source = "( ) [ ] { } , |";
    var lexer = Lexer.init(source);

    const expected = [_]token.TokenType{ .lparen, .rparen, .lbracket, .rbracket, .lbrace, .rbrace, .comma, .bar, .eof };

    for (expected) |expected_type| {
        const tok = lexer.nextToken();
        try std.testing.expectEqual(expected_type, tok.type);
    }
}
