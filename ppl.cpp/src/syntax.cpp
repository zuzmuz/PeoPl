#ifndef PEOPL_SYNTAX_CPP
#define PEOPL_SYNTAX_CPP
#include "common.cpp"
#include <cstring>

namespace syntax {
enum class TokenKind {
	// literals
	int_literal,
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
	plus,	  // +
	minus,	  // -
	times,	  // *
	by,		  // /
	mod,	  // %
	exponent, // ^

	// bitwise
	lshift, // <<
	rshift, // >>
	band,	// .&
	bor,	// .|
	bxor,	// .^
	bnot,	// ~

	// access
	dot,	   // .
	pipe,	   // |>
	propagate, // ?

	// comparisons
	eq, // =
	ge, // >=
	gt, // >
	le, // <=
	lt, // <

	// delimieters
	lparen,	  // (
	rparen,	  // )
	lbracket, // [
	rbracket, // ]
	lbrace,	  // {
	rbrace,	  // }

	// special
	comma,		 // delimiting expressions
	bar,		 // for capture blocks
	backslash,	 // for qualified identifiers
	appostrophe, // for type definitions
	arrow,		 // ->
	binding,	 // @
	positional,	 // $

	new_line,

	eof,
	invalid
};

struct Token {
	TokenKind kind;
	String value;
	usize line;
	usize column;
};

u8 is_utf8(u8 c) { return c & 0x80; }

char const * COMPACT_KEYWORDS = "ifcompfnandornot";
struct Keyword {
	TokenKind kind;
	String string;
};

const Keyword KEYWORDS[] = {
	{.kind = TokenKind::kword_if,
	 .string = {.ptr = (u8 *)COMPACT_KEYWORDS, .size = 2}},
	{.kind = TokenKind::kword_comp,
	 .string = {.ptr = (u8 *)COMPACT_KEYWORDS + 2, .size = 4}},
	{.kind = TokenKind::kword_fn,
	 .string = {.ptr = (u8 *)COMPACT_KEYWORDS + 6, .size = 2}},
	{.kind = TokenKind::kword_and,
	 .string = {.ptr = (u8 *)COMPACT_KEYWORDS + 8, .size = 3}},
	{.kind = TokenKind::kword_or,
	 .string = {.ptr = (u8 *)COMPACT_KEYWORDS + 11, .size = 2}},
	{.kind = TokenKind::kword_not,
	 .string = {.ptr = (u8 *)COMPACT_KEYWORDS + 13, .size = 3}},
};

struct Tokenizer {

	String source;
	u8 * start_of_token = nullptr;
	u8 * end_of_source = nullptr;
	u8 * cursor = nullptr;
	u32 current_rune = 0;

	usize line = 0;
	usize column = 0;

	Tokenizer() = delete;

	Token generate_token(TokenKind kind) const {
		return {
			.kind = kind,
			.value =
				{.ptr = start_of_token,
				 .size = cursor - start_of_token},
			.line = line,
			.column = column
		};
	}

	Token next_token() {
		this->start_of_token = this->cursor;

		if (skip_spaces_or_stop()) {
			return generate_token(TokenKind::eof);
		}

		if (current_rune == '\n') {
			return generate_token(TokenKind::new_line);
		}

		if (is_letter(current_rune)) {
			return consume_identifier();
		}

		if (is_digit(current_rune)) {
			return consume_number();
		}

		return generate_token(TokenKind::invalid);
	}

	Token consume_number() {
		if (current_rune == '0') {
			if (advance_or_stop()) {
				return generate_token(TokenKind::int_literal);
			}
			if (current_rune == 'x') {
				while (advance_or_stop()) {
					if (is_hex_number(k
				}
			}
		}
	}

	Token consume_identifier() {
		while (advance_or_stop()) {
			if (not(is_digit(current_rune) or
					is_letter(current_rune))) {
				break;
			}
		}

		String identifier_string = {
			.ptr = start_of_token, .size = cursor - start_of_token
		};

		for (Keyword keyword : KEYWORDS) {
			if (identifier_string == keyword.string) {
				return generate_token(keyword.kind);
			}
		}
		return generate_token(TokenKind::identifier);
	}

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

	bool skip_spaces_or_stop() {
		while (advance_or_stop()) {
			switch (current_rune) {
			case ' ':
			case '\t':
			case '\r':
				continue;
			default:
				return false;
			}
		}
		return true;
	}

	bool advance_or_stop() {
		if (cursor < end_of_source) {
			if (is_utf8(*cursor)) {
				// TODO: handle utf8
				return true;
			} else if (*cursor == 0) {
				// TODO: illegal state (store lexical errors)
				return true;
			} else {
				current_rune = *cursor;

				if (*cursor == '\n') {
					line += 1;
					column = 0;
				} else {
					column += 1;
				}
				cursor += 1;
				return false;
			}
		}
		return true;
	}
};
}; // namespace syntax

#endif
