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

enum class Precedence {
	lonely = 0,
	shotcirc_or = 1,
	shortcirc_and = 2,
	comp = 3,
	bor = 4,
	band = 5,
	bshift = 6,
	additive = 7,
	multiplicative = 8,
	exponent = 9,
	parenthesis = 10,
	access = 11,
};

enum class ExpressionKind {
	int_literal,
	identifier,
	tagged,
	accessed,
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

struct Accessed {
	usize prefix_expr_idx;
	Identifier field;
};

struct BinaryOp {
	TokenKind op;
	usize lhs_expr_idx;
	usize rhs_expr_idx;
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
	///   | Expression
	///   ;
	Expression parse_complex_expression() {
		switch (tokens[cursor].kind) {
		case TokenKind::identifier: {
			if (tokens[cursor + 1].kind == TokenKind::colon) {
				// Tagged Expression
				// identifier: basic_expression
				Identifier tag(cursor);
				cursor += 2;
				usize expr_idx = push_expression(parse_expression());
				return make_tagged(tag, expr_idx);
			} // if not follow through and parse expression
		}
		default:
			return parse_expression();
			// }
		}
	}

	/// Expression
	///   : Binding
	///   | PrimaryExpression Extension
	///   ;
	Expression parse_expression() {
		usize lhs_expr_idx =
			push_expression(parse_primary_expression());

		return parse_primary_expression();
	}

	/// PrimaryExpression
	///   : Literal
	///   | Identifier
	///   | ParenthesizedExpression
	///   | Positional
	///   ;
	///
	Expression parse_primary_expression() {
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
		case TokenKind::plus:
		case TokenKind::minus:
		case TokenKind::times:
		case TokenKind::by:
		case TokenKind::exponent:
		case TokenKind::kword_or:
		case TokenKind::kword_and:
		case TokenKind::mod:
		case TokenKind::lshift:
		case TokenKind::rshift:
		case TokenKind::band:
		case TokenKind::bor:
		case TokenKind::bxor:
		case TokenKind::bnot:
		case TokenKind::eq:
		case TokenKind::ge:
		case TokenKind::gt:
		case TokenKind::le:
		case TokenKind::lt:
			return parse_unary();
		default:
			return make_invalid();
		}
	}

	Expression parse_unary() { return {}; }

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
		Expression literal =
			make_int_literal(int_from_token(tokens[cursor]), cursor);

		if (tokens[cursor + 1].kind == TokenKind::lparen) {
			// TODO: calling a int literal error
		} else if (tokens[cursor + 1].kind == TokenKind::dot) {
			// Access operator
			cursor += 2;
			Expression accessed = parse_identifier();
			return

				return
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
		const syntax::Expression & expression,
		std::format_context & ctx
	) const {
		string_view value;
		switch (expression.kind) {
		case syntax::ExpressionKind::int_literal:
			value =
				std::format("{}", expression.value.int_literal.value);
			break;
		case syntax::ExpressionKind::identifier:
			value = std::format(
				"{}", expression.value.identifier.token_idx
			);
			break;
		case syntax::ExpressionKind::tagged:
		case syntax::ExpressionKind::nothing:
		case syntax::ExpressionKind::invalid:
			value = "";
			break;
		}

		return std::format_to(
			ctx.out(), "{} {}", expression.kind, value
		);
	}
};
