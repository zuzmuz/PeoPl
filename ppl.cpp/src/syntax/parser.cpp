#pragma once
#include "tokenizer+debug.cpp"
#include "tokenizer.cpp"
#include <format>
#include <memory>
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

enum class ExpressionKind {
	int_literal,
	identifier,
	tagged,
	nothing,
	invalid
};

struct Expression;

struct Nothing {};
struct Invalid {};

struct IntLiteral {
	usize value;
	usize token_idx;
};

struct Identifier {
	usize token_idx;
};

struct Tagged {
	Identifier tag;
	usize expr_idx;
};

union ExpressionValue {
	IntLiteral int_literal;
	Identifier identifier;
	Tagged tagged;
	Nothing nothing;
	Invalid invalid;
};

struct Expression {
	ExpressionKind kind;
	ExpressionValue value;
};

struct ExpressionList {
	std::vector<usize> expr_list_idx;
};

struct SyntaxTree {
	ExpressionList expression_list;
};

struct SyntaxError {
	i16 error_code;
};

Expression make_invalid() {
	return {.kind = ExpressionKind::invalid, .value = {}};
}

Expression make_tagged(Identifier tag, usize expr_idx) {
	return {
		.kind = ExpressionKind::tagged,
		.value = {.tagged = {.tag = tag, .expr_idx = expr_idx}}
	};
}

Expression make_identifier(Identifier tag) {
	return {
		.kind = ExpressionKind::identifier,
		.value = {.identifier = tag}
	};
}

Expression make_int_literal(u64 value, usize token_idx) {
	return {
		.kind = ExpressionKind::int_literal,
		.value = {
			.int_literal = {.value = value, .token_idx = token_idx}
		}
	};
}

struct Parser {
  private:
	Tokenizer tokenizer;
	std::vector<Token> tokens;
	std::vector<SyntaxError> errors;
	std::vector<Expression> expressions;

	usize cursor = 0;

	// const Token & move_cursor() {
	// 	tokens.push_back(tokenizer.next_token());
	// 	return tokens.back();
	// }
	//
	// const Token & cursor() { return tokens.back(); }
	//
	usize push_expression(Expression expression) {
		// std::println("pushing expression {}", expression.kind);
		expressions.push_back(expression);
		return expressions.size() - 1;
	}

  public:
	Parser(String source) : tokenizer(source) {
		Token token;
		do {
			token = tokenizer.next_token();
			tokens.push_back(token);
		} while (token.kind != TokenKind::eof);
	}

	SyntaxTree parse() {
		auto expression_list = parse_expression_list(TokenKind::eof);
		return {.expression_list = expression_list};
	}

	const Expression & get_expression(usize expr_idx) const {
		return expressions[expr_idx];
	}

	const std::vector<Token> get_tokens() const { return tokens; }

  private:
	/// ExpressionList
	ExpressionList parse_expression_list(TokenKind end_token_kind) {
		std::println("So we're here");
		std::vector<usize> expr_list_idx;
		expr_list_idx.push_back(
			push_expression(parse_complex_expression())
		);
		cursor += 1;
		while (tokens[cursor].kind != end_token_kind) {
			if (tokens[cursor].kind == TokenKind::comma or
				tokens[cursor].kind == TokenKind::new_line) {
				cursor += 1;
				skip_newlines();

				expr_list_idx.push_back(
					push_expression(parse_complex_expression())
				);
				cursor += 1;
			} else {
				// TODO: handle error properly
			}
		}

		return {.expr_list_idx = expr_list_idx};
	}

	void skip_newlines() {
		while (tokens[cursor].kind == TokenKind::new_line) {
			cursor += 1;
		}
	}

	/// ComplexExpression
	///   : TaggedExpression
	///   | BasicExpression
	///   ;
	Expression parse_complex_expression() {
		std::println("We should be parsing the complex expression");
		switch (tokens[cursor].kind) {
		case TokenKind::identifier: {
			if (tokens[cursor + 1].kind == TokenKind::colon) {
				// Tagged Expression
				// identifier: basic_expression
				Identifier tag(cursor);
				cursor += 2;
				usize expr_idx =
					push_expression(parse_basic_expression());
				return make_tagged(tag, expr_idx);
			} else {
				return parse_identifier();
			}
		}
		default:
			return parse_basic_expression();
			// }
		}
	}

	/// BasicExpression
	///   : SimpleExpression
	///   ;
	Expression parse_basic_expression() {
		return parse_simple_expression();
	}

	/// SimpleExpression
	///   : Literal
	///   | Identifier
	///   | parenthesized_expression
	///   ;
	///
	Expression parse_simple_expression() {
		std::println("Parsing simple expression");
		switch (tokens[cursor].kind) {
		case TokenKind::int_literal:
		case TokenKind::hex_literal:
		case TokenKind::oct_literal:
		case TokenKind::bin_literal:
			return parse_int_literal();
		case TokenKind::identifier:
			return parse_identifier();
		case TokenKind::lparen:
			return parse_parenthesis();
		default:
			return make_invalid();
		}
	}

	Expression parse_parenthesis() {
		// skip lparen token
		Expression expression = parse_complex_expression();
		return {};
	}

	Expression parse_identifier() {
		// TODO: might be call expressions
		return make_identifier(Identifier(cursor));
	}

	Expression parse_int_literal() {
		return make_int_literal(
			int_from_token(tokens[cursor]), cursor
		);
	}
};
}; // namespace syntax
   //

template <> struct std::formatter<syntax::ExpressionKind> {
	constexpr auto parse(std::format_parse_context & ctx) {
		return ctx.begin();
	}

	auto format(
		const syntax::ExpressionKind & kind, std::format_context & ctx
	) const {
		string_view name;
		switch (kind) {
		case syntax::ExpressionKind::int_literal:
			name = "int_literal";
			break;
		case syntax::ExpressionKind::identifier:
			name = "identifier";
			break;
		case syntax::ExpressionKind::tagged:
			name = "tagged";
			break;
		case syntax::ExpressionKind::nothing:
			name = "nothing";
			break;
		case syntax::ExpressionKind::invalid:
			name = "invalid";
			break;
		}

		return std::format_to(ctx.out(), "{}", name);
	}
};

template <> struct std::formatter<syntax::Expression> {
	// parse() handles format spec like {:.2f}
	constexpr auto parse(std::format_parse_context & ctx) {
		return ctx.begin(); // no custom format spec, just return
	}

	auto format(
		const syntax::Expression & expression, std::format_context & ctx
	) const {
		string_view value;
		switch (expression.kind) {
		case syntax::ExpressionKind::int_literal:
			value = std::format("{}", expression.value.int_literal.value);
			break;
		case syntax::ExpressionKind::identifier:
			value = std::format("{}", expression.value.identifier.token_idx);
			break;
		case syntax::ExpressionKind::tagged:
		case syntax::ExpressionKind::nothing:
		case syntax::ExpressionKind::invalid:
			value = "";
			break;
		}

		return std::format_to(ctx.out(), "{} {}", expression.kind, value);
	}
};
