#include "syntax/parser.cpp"
#include <catch2/catch_test_macros.hpp>
#include <print>

TEST_CASE("int literal") {
	syntax::Parser parser("0x1_2, 0b_10, 5\n0o1234,   0xff, 1000");
	// auto ast = parser.parse();
	// syntax::SyntaxTree ast(tokenizer);
	//
	// for (auto expression: ast.expression_list.items) {
	// 	std::println("{}", expression->value.int_literal.value);
	// }
	// std::println("{}", ast.tokens);
}
