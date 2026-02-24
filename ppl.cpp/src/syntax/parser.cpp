#pragma once
#include "tokenizer+debug.cpp"
#include "tokenizer.cpp"
#include <print>
#include <vector>

namespace syntax {

u8 int_from_char(u8 c) {
	if (c >= '0' and c <= '9')
		return c - '0';
	if (c >= 'a' and c <= 'f')
		return 10 + c - 'a';
	if (c >= 'A' and c <= 'F')
		return 10 + c - 'A';
	// FIXME: this should be unreachable
	return 0;
}

u64 int_from_string(String const & content, u8 base) {
	std::println("content {}", content);
	u64 value = 0;
	usize i = 0;
	if (base != 10)
		i = 2;
	for (; i < content.size; ++i) {
		if (content[i] == '_') {
			continue;
		}
		// FIXME: prevent overflow
		value = base * value + int_from_char(content[i]);
	}
	return value;
}

u64 int_from_token(Token const & token) {

	std::println("unreachable {}", token.kind);
	switch (token.kind) {
	case TokenKind::int_literal:
		return int_from_string(token.value, 10);
	case TokenKind::hex_literal:
		return int_from_string(token.value, 16);
	case TokenKind::oct_literal:
		return int_from_string(token.value, 8);
	case TokenKind::bin_literal:
		return int_from_string(token.value, 2);
	default:
		// unreachable
		return 0;
	}
}

enum class ExpressionKind { int_literal, nothing, invalid };

struct Nothing {};
struct Invalid {};

struct IntLiteral {
	usize value;
	const Token * token;
};

union ExpressionValue {
	IntLiteral int_literal;
	Nothing nothing;
	Invalid invalid;
};

struct Expression {
	ExpressionKind kind;
	ExpressionValue value;
};

struct ExpressionList {
	std::vector<Expression> items;
};

struct SyntaxTree {
	ExpressionList expression_list;
};

struct SyntaxError {
	i16 error_code;
};

struct Parser {
	Tokenizer tokenizer;
	Token cursor;
	std::vector<SyntaxError> errors;

	Parser(const char * source) : tokenizer(source) {
		tokenizer = Tokenizer(source);
	}

	SyntaxTree parse() {
		cursor = tokenizer.next_token();
		auto expression_list = parse_expression_list(TokenKind::eof);
		return {.expression_list = expression_list};
	}

	/// ExpressionList
	ExpressionList parse_expression_list(TokenKind end_token_kind) {
		std::vector<Expression> expressions;
		expressions.push_back(parse_expression());

		while (cursor.kind != end_token_kind) {
			cursor = tokenizer.next_token();
			if (cursor.kind == TokenKind::comma) {
				// skip_newlines();
				expressions.push_back(parse_expression());
			} else {
				// TODO: handle error properly
				break;
			}
		}

		return {.items = expressions};
	}

	Expression parse_expression() {
		switch (cursor.kind) {
		case TokenKind::int_literal:
		case TokenKind::hex_literal:
		case TokenKind::oct_literal:
		case TokenKind::bin_literal:
			return parse_int_literal();
		default:
			return {.kind = ExpressionKind::invalid, .value = {}};
		}
	}

	Expression parse_int_literal() {
		return {
			 .kind = ExpressionKind::int_literal,
			 .value = {
				  .int_literal = {
						.value = int_from_token(cursor), .token = &cursor
				  }
			 }
		};
	}
};
}; // namespace syntax
