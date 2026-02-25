#include "syntax/parser.cpp"
#include <catch2/catch_test_macros.hpp>
#include <print>

TEST_CASE("int literal") {
	std::println("are we parsing this");
	syntax::Parser parser("0x1_2, 0b_10, 5\n0o1234,   0xff, 1000");
	for (auto token: parser.get_tokens()) {
		std::println("token {}", token);
	}
	auto ast = parser.parse();

	for (auto expr_idx : ast.expression_list.expr_list_idx) {
		std::println(
			"expression {}",
			parser.get_expression(expr_idx)
		);
	}
	// std::println("{}", ast.tokens);
}
