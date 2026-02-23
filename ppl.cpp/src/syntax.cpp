#ifndef PEOPL_SYNTAX_CPP
#define PEOPL_SYNTAX_CPP
#include "common.cpp"
#include <cstring>
#include <format>
#include <print>

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

// TODO: move this elswhere

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

	Tokenizer(char const * source) {
		this->source.ptr = (u8 *)source;
		this->source.size = strlen(source);

		start_of_token = this->source.ptr;
		end_of_source = this->source.ptr + this->source.size;
		cursor = start_of_token;
		std::println("content {}", source);
	}

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

		std::println("start {}, cursor {}", *start_of_token, *cursor);

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
					if (not(is_hex_digit(current_rune) or
							current_rune == '_')) {
						break;
					}
				}
				return generate_token(TokenKind::int_literal);
			}

			if (current_rune == 'o') {
				// TODO: handle octal numbers
				return generate_token(TokenKind::invalid);
			}

			// TODO: handle binary
		}

		while (advance_or_stop()) {
			if (not is_digit(current_rune)) {
				break;
			}
		}
		return generate_token(TokenKind::int_literal);
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

template <> struct std::formatter<syntax::TokenKind> {
	constexpr auto parse(std::format_parse_context & ctx) {
		return ctx.begin();
	}

	auto format(
		const syntax::TokenKind & kind, std::format_context & ctx
	) const {
		string_view name;
		switch (kind) {
		case syntax::TokenKind::int_literal:
			name = "int_literal";
			break;
		case syntax::TokenKind::float_literal:
			name = "float_literal";
			break;
		case syntax::TokenKind::string_literal:
			name = "string_literal";
			break;
		case syntax::TokenKind::identifier:
			name = "identifier";
			break;
		case syntax::TokenKind::special:
			name = "special";
			break;
		case syntax::TokenKind::kword_if:
			name = "kword_if";
			break;
		case syntax::TokenKind::kword_comp:
			name = "kword_comp";
			break;
		case syntax::TokenKind::kword_fn:
			name = "kword_fn";
			break;
		case syntax::TokenKind::kword_and:
			name = "kword_and";
			break;
		case syntax::TokenKind::kword_or:
			name = "kword_or";
			break;
		case syntax::TokenKind::kword_not:
			name = "kword_not";
			break;
		case syntax::TokenKind::plus:
			name = "plus";
			break;
		case syntax::TokenKind::minus:
			name = "minus";
			break;
		case syntax::TokenKind::times:
			name = "times";
			break;
		case syntax::TokenKind::by:
			name = "by";
			break;
		case syntax::TokenKind::mod:
			name = "mod";
			break;
		case syntax::TokenKind::exponent:
			name = "exponent";
			break;
		case syntax::TokenKind::lshift:
			name = "lshift";
			break;
		case syntax::TokenKind::rshift:
			name = "rshift";
			break;
		case syntax::TokenKind::band:
			name = "band";
			break;
		case syntax::TokenKind::bor:
			name = "bor";
			break;
		case syntax::TokenKind::bxor:
			name = "bxor";
			break;
		case syntax::TokenKind::bnot:
			name = "bnot";
			break;
		case syntax::TokenKind::dot:
			name = "dot";
			break;
		case syntax::TokenKind::pipe:
			name = "pipe";
			break;
		case syntax::TokenKind::propagate:
			name = "propagate";
			break;
		case syntax::TokenKind::eq:
			name = "eq";
			break;
		case syntax::TokenKind::ge:
			name = "ge";
			break;
		case syntax::TokenKind::gt:
			name = "gt";
			break;
		case syntax::TokenKind::le:
			name = "le";
			break;
		case syntax::TokenKind::lt:
			name = "lt";
			break;
		case syntax::TokenKind::lparen:
			name = "lparen";
			break;
		case syntax::TokenKind::rparen:
			name = "rparen";
			break;
		case syntax::TokenKind::lbracket:
			name = "lbracket";
			break;
		case syntax::TokenKind::rbracket:
			name = "rbracket";
			break;
		case syntax::TokenKind::lbrace:
			name = "lbrace";
			break;
		case syntax::TokenKind::rbrace:
			name = "rbrace";
			break;
		case syntax::TokenKind::comma:
			name = "comma";
			break;
		case syntax::TokenKind::bar:
			name = "bar";
			break;
		case syntax::TokenKind::backslash:
			name = "backslash";
			break;
		case syntax::TokenKind::appostrophe:
			name = "appostrophe";
			break;
		case syntax::TokenKind::arrow:
			name = "arrow";
			break;
		case syntax::TokenKind::binding:
			name = "binding";
			break;
		case syntax::TokenKind::positional:
			name = "positional";
			break;
		case syntax::TokenKind::new_line:
			name = "new_line";
			break;
		case syntax::TokenKind::eof:
			name = "eof";
			break;
		case syntax::TokenKind::invalid:
			name = "invalid";
			break;
		}
		return std::format_to(ctx.out(), "{}", name);
	}
};

template <> struct std::formatter<String> {
	// parse() handles format spec like {:.2f}
	constexpr auto parse(std::format_parse_context & ctx) {
		return ctx.begin(); // no custom format spec, just return
	}

	auto format(const String & s, std::format_context & ctx) const {
		std::string_view view(
			reinterpret_cast<const char *>(s.ptr), s.size
		);
		return std::format_to(ctx.out(), "{}", view);
	}
};

template <> struct std::formatter<syntax::Token> {
	// parse() handles format spec like {:.2f}
	constexpr auto parse(std::format_parse_context & ctx) {
		return ctx.begin(); // no custom format spec, just return
	}

	auto format(
		const syntax::Token & token, std::format_context & ctx
	) const {
		return std::format_to(
			ctx.out(), "Token({}, {})", token.kind, token.value
		);
	}
};

#endif
