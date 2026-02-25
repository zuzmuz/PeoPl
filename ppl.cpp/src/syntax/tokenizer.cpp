#pragma once
#include "../common.cpp"
#include <compare>
#include <cstring>

namespace syntax {

/// Represents token kinds
enum class TokenKind {
	// literals
	int_literal,
	hex_literal,
	oct_literal,
	bin_literal,
	float_literal,
	imaginary_literal,
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
	colon, // for expression definitions
	arrow, // ->
	binding, // @
	positional, // $

	comment,
	new_line,

	eof,
	invalid
};

u8 is_utf8(u8 c) { return c & 0x80; }

String COMPACT_KEYWORDS = "ifcompfnandornot";
struct Keyword {
	TokenKind kind;
	String string;
};

const Keyword KEYWORDS[] = {
	{.kind = TokenKind::kword_if,
	 .string = COMPACT_KEYWORDS.substring(0, 2)},
	{.kind = TokenKind::kword_comp,
	 .string = COMPACT_KEYWORDS.substring(2, 6)},
	{.kind = TokenKind::kword_fn,
	 .string = COMPACT_KEYWORDS.substring(6, 8)},
	{.kind = TokenKind::kword_and,
	 .string = COMPACT_KEYWORDS.substring(8, 11)},
	{.kind = TokenKind::kword_or,
	 .string = COMPACT_KEYWORDS.substring(11, 13)},
	{.kind = TokenKind::kword_not,
	 .string = COMPACT_KEYWORDS.substring(13, 16)}
};

/// Line and column in original source
struct Point {
	usize line;
	usize column;

	bool operator==(const Point &) const = default;
	auto operator<=>(const Point &) const = default;
};

struct Token {
	TokenKind kind;
	String value;
	Point start;
	Point end;

	bool operator==(const Token &) const = default;
};

struct Tokenizer {

  private:
	const String source;
	usize start_of_token = 0;
	usize next_cursor = 0;
	usize current_cursor = 0;
	u32 current_rune = 0;
	u32 next_rune = 0;

	Point start = {.line = 0, .column = 0};
	Point end = {.line = 0, .column = 0};

	Token generate_token(TokenKind kind) const {
		return {
			.kind = kind,
			.value = source.substring(start_of_token, current_cursor),
			.start = start,
			.end = end
		};
	}

	Token consume_multi_line_string() {
		while (next_rune != '\n' and next_rune != 0) {
			advance();
		}
		return generate_token(TokenKind::string_literal);
	}

	Token consume_string() {
		while (next_rune != '"') {
			if (next_rune == '\n' or next_rune == 0) {
				return generate_token(TokenKind::invalid);
			}
			advance();
		}
		return generate_token(TokenKind::string_literal);
	}

	Token consume_comment() {
		while (next_rune != '\n' and next_rune != 0) {
			advance();
		}
		return generate_token(TokenKind::comment);
	}

	Token consume_number() {
		if (current_rune == '0') {
			advance();
			switch (current_rune) {
			case '0':
				return generate_token(TokenKind::invalid);
			case 'x':
				while (is_hex_digit(next_rune) or next_rune == '_') {
					advance();
				}
				return generate_token(TokenKind::hex_literal);
			case 'o':
				while (is_oct_digit(next_rune) or next_rune == '_') {
					advance();
				}
				return generate_token(TokenKind::oct_literal);
			case 'b':
				while (is_binary_digit(next_rune) or
					   next_rune == '_') {
					advance();
				}
				return generate_token(TokenKind::bin_literal);
			}
		}

		while (is_digit(next_rune) or next_rune == '_') {
			advance();
		}

		return generate_token(TokenKind::int_literal);
	}

	Token consume_identifier() {
		while (is_digit(next_rune) or is_letter(next_rune)) {
			advance();
		}

		String identifier_string =
			source.substring(start_of_token, current_cursor);

		for (Keyword keyword : KEYWORDS) {
			if (identifier_string == keyword.string) {
				return generate_token(keyword.kind);
			}
		}
		return generate_token(TokenKind::identifier);
	}

	// TODO: consume bindings
	// TODO: consume positionals

	bool is_letter(u32 rune) const {
		return (rune >= 'a' and rune <= 'z') or
			   (rune >= 'A' and rune <= 'Z');
	}

	bool is_digit(u32 rune) const {
		return rune >= '0' and rune <= '9';
	}

	bool is_hex_digit(u32 rune) const {
		return (rune >= '0' and rune <= '9') or
			   (rune >= 'a' and rune <= 'f') or
			   (rune >= 'A' and rune <= 'F');
	}

	bool is_oct_digit(u32 rune) const {
		return rune >= '0' and rune <= '7';
	}

	bool is_binary_digit(u32 rune) const {
		return rune >= '0' and rune <= '1';
	}

	void skip_spaces() {
		for (;;) {
			switch (next_rune) {
			case ' ':
			case '\t':
			case '\r':
				advance();
				break;
			default:
				return;
			}
		}
	}

	void advance() {
		current_rune = next_rune;
		current_cursor = next_cursor;
		if (next_cursor < source.size) {
			if (is_utf8(source[next_cursor])) {
				// TODO: handle utf8
			} else if (source[next_cursor] == 0) {
				// TODO: illegal state (store lexical errors)
			} else {
				next_rune = source[next_cursor];

				if (current_rune == '\n') {
					end.line += 1;
					end.column = 0;
				} else {
					end.column += 1;
				}
				next_cursor += 1;
			}
		} else {
			next_rune = 0;
			if (current_rune == '\n') {
				end.line += 1;
				end.column = 0;
			} else if (current_rune != 0) {
				end.column += 1;
			}
		}
	}

  public:
	Tokenizer(String source) : source(source) {
		advance();
		// resetting after first advancing
		start = {.line = 0, .column = 0};
		end = {.line = 0, .column = 0};
	}

	Token next_token() {
		skip_spaces();

		this->start_of_token = this->current_cursor;
		this->start = this->end;

		advance();

		if (current_rune == '\n') {
			return generate_token(TokenKind::new_line);
		}

		if (is_digit(current_rune)) {
			return consume_number();
		}

		if (is_letter(current_rune)) {
			return consume_identifier();
		}

		switch (current_rune) {
		case '=':
			return generate_token(TokenKind::eq);
		case '+':
			return generate_token(TokenKind::plus);
			break;
		case '*':
			return generate_token(TokenKind::times);
			break;
		case '%':
			return generate_token(TokenKind::mod);
			break;
		case '^':
			return generate_token(TokenKind::exponent);
			break;
		case '~':
			return generate_token(TokenKind::bnot);
			break;
		case '(':
			return generate_token(TokenKind::lparen);
			break;
		case ')':
			return generate_token(TokenKind::rparen);
			break;
		case '[':
			return generate_token(TokenKind::lbracket);
			break;
		case ']':
			return generate_token(TokenKind::rbracket);
			break;
		case '{':
			return generate_token(TokenKind::lbrace);
			break;
		case '}':
			return generate_token(TokenKind::rbrace);
			break;
		case ',':
			return generate_token(TokenKind::comma);
			break;
		case '\\':
			return generate_token(TokenKind::backslash);
			break;
		case '\'':
			return generate_token(TokenKind::appostrophe);
			break;
		case ':':
			return generate_token(TokenKind::colon);
			break;
		case '@':
			return consume_identifier();
			return generate_token(TokenKind::binding);
			break;
		case '$':
			return generate_token(TokenKind::positional);
			break;
		case '?':
			return generate_token(TokenKind::propagate);
		case '_':
			return generate_token(TokenKind::special);
			break;

		// Multi-character possibilities
		case '-':
			if (next_rune == '>') {
				advance();
				return generate_token(TokenKind::arrow);
			} else {
				return generate_token(TokenKind::minus);
			}
			break;
		case '/':
			if (next_rune == '/') {
				advance();
				return consume_comment();
			} else {
				return generate_token(TokenKind::by);
			}
			break;
		case '>':
			if (next_rune == '=') {
				advance();
				return generate_token(TokenKind::ge);
			} else {
				return generate_token(TokenKind::gt);
			}
			break;
		case '<':
			if (next_rune == '=') {
				advance();
				return generate_token(TokenKind::le);
			} else {
				return generate_token(TokenKind::lt);
			}
			break;
		case '.':
			if (next_rune == '&') {
				advance();
				return generate_token(TokenKind::band);
			} else if (next_rune == '|') {
				advance();
				return generate_token(TokenKind::bor);
			} else if (next_rune == '^') {
				advance();
				return generate_token(TokenKind::bxor);
			} else {
				return generate_token(TokenKind::dot);
			}
		case '|':
			if (next_rune == '>') {
				advance();
				return generate_token(TokenKind::pipe);
			} else {
				return generate_token(TokenKind::bar);
			}
		case '"':
			if (next_rune == '"') {
				advance();
				if (next_rune == '"') {
					advance();
					return consume_multi_line_string();
				}
				return generate_token(TokenKind::string_literal);
			} else {
				return consume_string();
			}
		}

		return generate_token(TokenKind::eof);
	}
};
}; // namespace syntax
