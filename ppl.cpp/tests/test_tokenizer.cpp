#include "syntax/tokenizer+debug.cpp"
#include "syntax/tokenizer.cpp"
#include <catch2/catch_test_macros.hpp>
#include <print>

TEST_CASE("keywords") {

	char const * string =
		 " comp   if fnfn not \n   and  or    fn  compiffnnotandor";
	auto tokenizer = syntax::Tokenizer(string);
	syntax::Token token;

	syntax::Token reference_tokens[] = {
		 {.kind = syntax::TokenKind::kword_comp,
		  .value = {.ptr = (u8 *)(string + 1), .size = 4},
		  .start = {.line = 0, .column = 1},
		  .end = {.line = 0, .column = 5}},
		 {.kind = syntax::TokenKind::kword_if,
		  .value = {.ptr = (u8 *)(string + 8), .size = 2},
		  .start = {.line = 0, .column = 8},
		  .end = {.line = 0, .column = 10}},
		 {.kind = syntax::TokenKind::identifier,
		  .value = {.ptr = (u8 *)(string + 11), .size = 4},
		  .start = {.line = 0, .column = 11},
		  .end = {.line = 0, .column = 15}},
		 {.kind = syntax::TokenKind::kword_not,
		  .value = {.ptr = (u8 *)(string + 16), .size = 3},
		  .start = {.line = 0, .column = 16},
		  .end = {.line = 0, .column = 19}},
		 {.kind = syntax::TokenKind::new_line,
		  .value = {.ptr = (u8 *)(string + 20), .size = 1},
		  .start = {.line = 0, .column = 20},
		  .end = {.line = 1, .column = 0}},
		 {.kind = syntax::TokenKind::kword_and,
		  .value = {.ptr = (u8 *)(string + 24), .size = 3},
		  .start = {.line = 1, .column = 3},
		  .end = {.line = 1, .column = 6}},
		 {.kind = syntax::TokenKind::kword_or,
		  .value = {.ptr = (u8 *)(string + 29), .size = 2},
		  .start = {.line = 1, .column = 8},
		  .end = {.line = 1, .column = 10}},
		 {.kind = syntax::TokenKind::kword_fn,
		  .value = {.ptr = (u8 *)(string + 35), .size = 2},
		  .start = {.line = 1, .column = 14},
		  .end = {.line = 1, .column = 16}},
		 {.kind = syntax::TokenKind::identifier,
		  .value = {.ptr = (u8 *)(string + 39), .size = 16},
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
	char const * string = ",:"
								 "\'"
								 "? |>"
								 "| > < = ~"
								 "-> >= <=";

	auto tokenizer = syntax::Tokenizer(string);
	syntax::Token token;

	syntax::Token reference_tokens[] = {
		 {
			  .kind = syntax::TokenKind::comma,
			  .value = {.ptr = (u8 *)string, .size = 1},
			  .start = {.line = 0, .column = 0},
			  .end = {.line = 0, .column = 1},
		 },
		 {
			  .kind = syntax::TokenKind::colon,
			  .value = {.ptr = (u8 *)(string + 1), .size = 1},
			  .start = {.line = 0, .column = 1},
			  .end = {.line = 0, .column = 2},
		 }
	};

	for (auto reference_token : reference_tokens) {
		token = tokenizer.next_token();

		std::println("token {}", token);
		std::println("reference token {}", reference_token);
		std::println("----");

		REQUIRE(reference_token == token);
	}
}

TEST_CASE("multi line strings") {
	char const * string = "\"\"\" this is a multiline string\n"
								 "\"\"\" we do";

	auto tokenizer = syntax::Tokenizer(string);
	syntax::Token token;

	syntax::Token reference_tokens[] = {
		 {
			  .kind = syntax::TokenKind::string_literal,
			  .value = {.ptr = (u8 *)string, .size = 30},
			  .start = {.line = 0, .column = 0},
			  .end = {.line = 0, .column = 30},
		 },
		 {
			  .kind = syntax::TokenKind::new_line,
			  .value = {.ptr = (u8 *)(string +30), .size = 1},
			  .start = {.line = 0, .column = 30},
			  .end = {.line = 1, .column = 0},
		 },
		 {
			  .kind = syntax::TokenKind::string_literal,
			  .value = {.ptr = (u8 *)(string + 31), .size = 9},
			  .start = {.line = 1, .column = 0},
			  .end = {.line = 1, .column = 9},
		 }
	};

	for (auto reference_token : reference_tokens) {
		token = tokenizer.next_token();

		std::println("token {}", token);
		std::println("reference token {}", reference_token);
		std::println("----");

		REQUIRE(reference_token == token);
	}
}
