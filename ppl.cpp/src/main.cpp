#include "syntax/tokenizer+debug.cpp"
#include "syntax/tokenizer.cpp"
#include <print>

int main() {
	char const * string = "comp   if (  i+ 234) /  siz   , fn .| |hi @a|\n x: fn() -> {}";

	auto tokenizer = syntax::Tokenizer(string);
	int i = 0;	
	syntax::Token token;
	do {
		token = tokenizer.next_token();
		std::println("token {}", token);
		if (i == 25) break;
		i += 1;
	} while (token.kind != syntax::TokenKind::eof);

	return 0;
}
