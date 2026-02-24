#pragma once
#include "tokenizer.cpp"
#include <vector>

namespace syntax {

enum class ExpressionKind { int_literal, nothing };

struct Nothing {};

struct IntLiteral {
	usize value;
	const Token * token;
};

union ExpressionValue {
	IntLiteral int_literal;
	Nothing nothing;
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

struct Parser {
	Tokenizer tokenizer;
	Token next_token;

	SyntaxTree parse(const char * source) {
		tokenizer = Tokenizer(source);

		auto expression_list = parse_expression_list(TokenKind::eof);

		return {.expression_list = expression_list};
	}

	ExpressionList parse_expression_list(TokenKind end_token_kind) {
		std::vector<Expression> expressions;
		expressions.push_back(parse_expression());
		
		while (next_token.kind != end_token_kind) {
			expressions.push_back(parse_expression());
		}

		return {.items = expressions};
	}

	Expression parse_expression() {
		return {};
	}
};

}; // namespace syntax
