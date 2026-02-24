#include <catch2/catch_test_macros.hpp>
#include <print>
#include "syntax/parser.cpp"

TEST_CASE("int literal") {
	char const * string = "42";
	syntax::Tokenizer tokenizer(string);

	// syntax::SyntaxTree ast(tokenizer);
	// 
	// for (auto token: ast.tokens) {
	// 	std::println("{}", token);
	// }
	// std::println("{}", ast.tokens);
}
