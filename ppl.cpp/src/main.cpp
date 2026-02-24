#include <print>
#include "common.cpp"
#include "syntax.cpp"

int main() {
	char const * string = "(i+ 234) / siz";

	auto tokenizer = syntax::Tokenizer(string);
	
	syntax::Token token;
	do {
		token = tokenizer.next_token();
		std::println("token {}", token);
	} while (token.kind != syntax::TokenKind::eof);

	return 0;
}
