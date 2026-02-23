#include <print>
#include "common.cpp"
#include "syntax.cpp"

int main() {
	char const * string = "if";

	auto tokenizer = syntax::Tokenizer(string);

	auto token = tokenizer.next_token();
	
	std::println("token {}", token);

	return 0;
}
