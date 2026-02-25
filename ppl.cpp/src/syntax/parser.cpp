#pragma once
#include "tokenizer+debug.cpp"
#include "tokenizer.cpp"
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
	const Token * token;
};

struct Identifier {
	const Token * token;
};

struct Tagged {
	Identifier tag;
	const Expression * expression;
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
	std::vector<const Expression *> items;
};

struct SyntaxTree {
	ExpressionList expression_list;
};

struct SyntaxError {
	i16 error_code;
};

Expression
make_tagged(Identifier tag, const Expression * expression) {
	return {
		.kind = ExpressionKind::tagged,
		.value = {.tagged = {.tag = tag, .expression = expression}}
	};
}
struct Parser {
  private:
	Tokenizer tokenizer;
	std::vector<Token> tokens;
	std::vector<SyntaxError> errors;
	std::vector<Expression> expressions;

	const Token & move_cursor() {
		tokens.push_back(tokenizer.next_token());
		return tokens.back();
	}

	const Token & cursor() { return tokens.back(); }

	const Expression * push_expression(Expression expression) {
		expressions.push_back(expression);
		return &expressions.back();
	}

  public:
	Parser(const char * source) : tokenizer(source) {
		tokenizer = Tokenizer(source);
	}

	SyntaxTree parse() {
		auto expression_list = parse_expression_list(TokenKind::eof);
		return {.expression_list = expression_list};
	}

  private:
	/// ExpressionList
	ExpressionList parse_expression_list(TokenKind end_token_kind) {
		std::vector<const Expression *> exps;
		exps.push_back(push_expression(parse_complex_expression()));

		auto cursor = move_cursor();
		while (cursor.kind != end_token_kind) {
			cursor = move_cursor();
			if (cursor.kind == TokenKind::comma or
				cursor.kind == TokenKind::new_line) {

				move_cursor();
				skip_newlines();

				expressions.push_back(parse_complex_expression());
			} else {
				// TODO: handle error properly
			}
		}

		return {.items = exps};
	}

	void skip_newlines() {
		// while (cursor.kind == TokenKind::new_line) {
		// 	move_cursor();
		// }
	}

	/// ComplexExpression
	///   : TaggedExpression
	///   | BasicExpression
	///   ;
	Expression parse_complex_expression() {
		// switch (cursor.kind) {
		// case TokenKind::identifier: {
		// 	Token identifier_token = cursor;
		// 	move_cursor();
		// 	if (cursor.kind == TokenKind::colon) {
		// 		move_cursor();
		// 		auto rhs = parse_basic_expression();
		// 		return {
		// 			.kind = ExpressionKind::tagged, .value = {
		// 				.tagged
		// 			} else {
		// 				// TODO: other cases
		// 				return {
		// 					.kind = ExpressionKind::identifier,
		// 					.value = {
		// 						.identifier = {
		// 							.token = &identifier_token
		// 						}
		// 					}
		// 				};
		// 			}
		// 		}
		// 	}
		// }
		// default:
		return parse_simple_expression();
		// }
	}

	/// TaggedExpression
	///   : Identifier BasicExpression
	///   ;
	Expression parse_tagged_expression() { return {}; }

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
		auto cursor = move_cursor();
		switch (cursor.kind) {
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
			return {.kind = ExpressionKind::invalid, .value = {}};
		}
	}

	Expression parse_parenthesis() {
		// skip lparen token
		Expression expression = parse_complex_expression();
		return {};
	}

	Expression parse_identifier() {
		return {};
		// return {
		// 	.kind = ExpressionKind::identifier,
		// 	.value = {.identifier = {.token = &cursor}}
		// };
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
