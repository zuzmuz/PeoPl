#include <catch2/catch_test_macros.hpp>
#include <print>
#include "syntax/tokenizer.cpp"
#include "syntax/tokenizer+debug.cpp"

TEST_CASE("keywords") {

	String string =
		 " comp   if fnfn not \n   and  or    fn  compiffnnotandor";
	auto tokenizer = syntax::Tokenizer(string);

	syntax::Token token;

	syntax::Token reference_tokens[] = {
		 {.kind = syntax::TokenKind::kword_comp,
		  .value = string.substring(1, 5),
		  .start = {.line = 0, .column = 1},
		  .end = {.line = 0, .column = 5}},
		 {.kind = syntax::TokenKind::kword_if,
		  .value = string.substring(8, 10),
		  .start = {.line = 0, .column = 8},
		  .end = {.line = 0, .column = 10}},
		 {.kind = syntax::TokenKind::identifier,
		  .value = string.substring(11, 15),
		  .start = {.line = 0, .column = 11},
		  .end = {.line = 0, .column = 15}},
		 {.kind = syntax::TokenKind::kword_not,
		  .value = string.substring(16, 19),
		  .start = {.line = 0, .column = 16},
		  .end = {.line = 0, .column = 19}},
		 {.kind = syntax::TokenKind::new_line,
		  .value = string.substring(20, 21),
		  .start = {.line = 0, .column = 20},
		  .end = {.line = 1, .column = 0}},
		 {.kind = syntax::TokenKind::kword_and,
		  .value = string.substring(24, 27),
		  .start = {.line = 1, .column = 3},
		  .end = {.line = 1, .column = 6}},
		 {.kind = syntax::TokenKind::kword_or,
		  .value = string.substring(29, 31),
		  .start = {.line = 1, .column = 8},
		  .end = {.line = 1, .column = 10}},
		 {.kind = syntax::TokenKind::kword_fn,
		  .value = string.substring(35, 37),
		  .start = {.line = 1, .column = 14},
		  .end = {.line = 1, .column = 16}},
		 {.kind = syntax::TokenKind::identifier,
		  .value = string.substring(39, 55),
		  .start = {.line = 1, .column = 18},
		  .end = {.line = 1, .column = 34}},
	};

	for (auto reference_token : reference_tokens) {
		token = tokenizer.next_token();

		std::println("token {}", token);
		std::println("reference token {}", reference_token);
		std::println("----");

		REQUIRE(reference_token == token);
	}
}

TEST_CASE("operators") {
	// char const * string = ",:"
	// 							 "\'"
	// 							 "? |>"
	// 							 "| > < = ~"
	// 							 "-> >= <=";
	//
	// auto tokenizer = syntax::Tokenizer(string);
	// syntax::Token token;
	//
	// syntax::Token reference_tokens[] = {
	// 	 {
	// 		  .kind = syntax::TokenKind::comma,
	// 		  .value = {.data = (u8 *)string, .size = 1},
	// 		  .start = {.line = 0, .column = 0},
	// 		  .end = {.line = 0, .column = 1},
	// 	 },
	// 	 {
	// 		  .kind = syntax::TokenKind::colon,
	// 		  .value = {.data = (u8 *)(string + 1), .size = 1},
	// 		  .start = {.line = 0, .column = 1},
	// 		  .end = {.line = 0, .column = 2},
	// 	 }
	// };
	//
	// for (auto reference_token : reference_tokens) {
	// 	token = tokenizer.next_token();
	//
	// 	std::println("token {}", token);
	// 	std::println("reference token {}", reference_token);
	// 	std::println("----");
	//
	// 	REQUIRE(reference_token == token);
	// }
}

TEST_CASE("multi line strings") {
	// char const * string = "\"\"\" this is a multiline string\n"
	// 							 "\"\"\" we do";
	//
	// auto tokenizer = syntax::Tokenizer(string);
	// syntax::Token token;
	//
	// syntax::Token reference_tokens[] = {
	// 	 {
	// 		  .kind = syntax::TokenKind::string_literal,
	// 		  .value = {.data = (u8 *)string, .size = 30},
	// 		  .start = {.line = 0, .column = 0},
	// 		  .end = {.line = 0, .column = 30},
	// 	 },
	// 	 {
	// 		  .kind = syntax::TokenKind::new_line,
	// 		  .value = {.data = (u8 *)(string +30), .size = 1},
	// 		  .start = {.line = 0, .column = 30},
	// 		  .end = {.line = 1, .column = 0},
	// 	 },
	// 	 {
	// 		  .kind = syntax::TokenKind::string_literal,
	// 		  .value = {.data = (u8 *)(string + 31), .size = 9},
	// 		  .start = {.line = 1, .column = 0},
	// 		  .end = {.line = 1, .column = 9},
	// 	 }
	// };
	//
	// for (auto reference_token : reference_tokens) {
	// 	token = tokenizer.next_token();
	//
	// 	std::println("token {}", token);
	// 	std::println("reference token {}", reference_token);
	// 	std::println("----");
	//
	// 	REQUIRE(reference_token == token);
	// }
}
