#ifndef PEOPL_SYNTAX_CPP
#define PEOPL_SYNTAX_CPP
#include "common.cpp"

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

	eof,
	invalid
};

struct Token {
	TokenKind kind;
	String value;
	// usize line;
	// usize column;
};

struct Tokenizer {
	String source;
	u8 * start;
	u8 * current;

	bool is_at_end() const {
		return this->current >= this->source.ptr + this->source.size;
	}

	Token next_token() {
		if (this->is_at_end()) {
			return {
				.kind = TokenKind::eof,
				.value = {.ptr = this->start, .size = 1}
				// .line = this->line,
				// .column = this->column
			};
		}

		const u8 c = this->advance();

		return {
			.kind = TokenKind::invalid,
			.value = {.ptr = this->start, .size = 1}
		};
	}

	u8 advance() {
		const u8 c = *current;
		current++;
		// column++;
		return c;
	}
};
}; // namespace syntax

#endif
