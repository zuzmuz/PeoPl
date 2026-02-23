#include <print>
#include "common.cpp"
#include "syntax.cpp"

// struct Token {
// 	size_t size;
// 	size_t line;
// 	size_t column;
// 	TokenType type;
// 	const char* lexem;
// };
//
//
// enum class ExpressionTypeTag {
// 	int_literal,
// };
//
// union ExpressionTypeValue {
// 	size_t int_literal;
// };
//
// struct Expression {
// 	ExpressionTypeTag tag;
// 	ExpressionTypeValue value;
// };

// struct SyntaxTree {};
//
// SyntaxTree parse(const char* content) {
// 	return {};
// }

int main() {
	std::println("Hello world");

	u8 const * string = (u8*)"😂";
	
	for (int i=0; i<5; ++i) {
		std::print("{} {} ", i, string[i]&0x80);
	}
	return 0;
}
