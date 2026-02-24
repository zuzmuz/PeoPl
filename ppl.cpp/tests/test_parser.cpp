#include <catch2/catch_test_macros.hpp>
#include <print>
#include "syntax/parser.cpp"

TEST_CASE("int literal") {
	char const * string = "0xff_ff_ff_ff";
	syntax::Parser parser(string);
	auto ast = parser.parse();
	// syntax::SyntaxTree ast(tokenizer);
	// 
	for (auto expression: ast.expression_list.items) {
		std::println("{}", expression.value.int_literal.value);
	}
	// std::println("{}", ast.tokens);
}
