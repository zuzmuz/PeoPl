#include "peopl.cpp"
#include <print>

int main() {
	char const * string = "comp   if (  i+ 234) /  siz   , fn .| |hi "
						  "@a|\n x: fn() -> {}";

	auto tokenizer = syntax::Tokenizer(string);
	syntax::Token token;
	do {
		token = tokenizer.next_token();
		std::println("token {}", token);
	} while (token.kind != syntax::TokenKind::eof);

	return 0;
}
