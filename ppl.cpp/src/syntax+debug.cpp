#include "syntax.cpp"
#include <format>

template <> struct std::formatter<syntax::TokenKind> {
	constexpr auto parse(std::format_parse_context & ctx) {
		return ctx.begin();
	}

	auto format(
		const syntax::TokenKind & kind, std::format_context & ctx
	) const {
		string_view name;
		switch (kind) {
		case syntax::TokenKind::int_literal:
			name = "int_literal";
			break;
		case syntax::TokenKind::hex_literal:
			name = "hex_literal";
			break;
		case syntax::TokenKind::oct_literal:
			name = "oct_literal";
			break;
		case syntax::TokenKind::bin_literal:
			name = "bin_literal";
			break;
		case syntax::TokenKind::imaginary_literal:
			name = "imaginary_literal";
			break;
		case syntax::TokenKind::float_literal:
			name = "float_literal";
			break;
		case syntax::TokenKind::string_literal:
			name = "string_literal";
			break;
		case syntax::TokenKind::identifier:
			name = "identifier";
			break;
		case syntax::TokenKind::special:
			name = "special";
			break;
		case syntax::TokenKind::kword_if:
			name = "kword_if";
			break;
		case syntax::TokenKind::kword_comp:
			name = "kword_comp";
			break;
		case syntax::TokenKind::kword_fn:
			name = "kword_fn";
			break;
		case syntax::TokenKind::kword_and:
			name = "kword_and";
			break;
		case syntax::TokenKind::kword_or:
			name = "kword_or";
			break;
		case syntax::TokenKind::kword_not:
			name = "kword_not";
			break;
		case syntax::TokenKind::plus:
			name = "plus";
			break;
		case syntax::TokenKind::minus:
			name = "minus";
			break;
		case syntax::TokenKind::times:
			name = "times";
			break;
		case syntax::TokenKind::by:
			name = "by";
			break;
		case syntax::TokenKind::mod:
			name = "mod";
			break;
		case syntax::TokenKind::exponent:
			name = "exponent";
			break;
		case syntax::TokenKind::lshift:
			name = "lshift";
			break;
		case syntax::TokenKind::rshift:
			name = "rshift";
			break;
		case syntax::TokenKind::band:
			name = "band";
			break;
		case syntax::TokenKind::bor:
			name = "bor";
			break;
		case syntax::TokenKind::bxor:
			name = "bxor";
			break;
		case syntax::TokenKind::bnot:
			name = "bnot";
			break;
		case syntax::TokenKind::dot:
			name = "dot";
			break;
		case syntax::TokenKind::pipe:
			name = "pipe";
			break;
		case syntax::TokenKind::propagate:
			name = "propagate";
			break;
		case syntax::TokenKind::eq:
			name = "eq";
			break;
		case syntax::TokenKind::ge:
			name = "ge";
			break;
		case syntax::TokenKind::gt:
			name = "gt";
			break;
		case syntax::TokenKind::le:
			name = "le";
			break;
		case syntax::TokenKind::lt:
			name = "lt";
			break;
		case syntax::TokenKind::lparen:
			name = "lparen";
			break;
		case syntax::TokenKind::rparen:
			name = "rparen";
			break;
		case syntax::TokenKind::lbracket:
			name = "lbracket";
			break;
		case syntax::TokenKind::rbracket:
			name = "rbracket";
			break;
		case syntax::TokenKind::lbrace:
			name = "lbrace";
			break;
		case syntax::TokenKind::rbrace:
			name = "rbrace";
			break;
		case syntax::TokenKind::comma:
			name = "comma";
			break;
		case syntax::TokenKind::bar:
			name = "bar";
			break;
		case syntax::TokenKind::backslash:
			name = "backslash";
			break;
		case syntax::TokenKind::appostrophe:
			name = "appostrophe";
			break;
		case syntax::TokenKind::colon:
			name = "colon";
			break;
		case syntax::TokenKind::arrow:
			name = "arrow";
			break;
		case syntax::TokenKind::binding:
			name = "binding";
			break;
		case syntax::TokenKind::positional:
			name = "positional";
			break;
		case syntax::TokenKind::new_line:
			name = "new_line";
			break;
		case syntax::TokenKind::comment:
			name = "comment";
			break;
		case syntax::TokenKind::eof:
			name = "eof";
			break;
		case syntax::TokenKind::invalid:
			name = "invalid";
			break;
		}
		return std::format_to(ctx.out(), "{}", name);
	}
};

template <> struct std::formatter<String> {
	// parse() handles format spec like {:.2f}
	constexpr auto parse(std::format_parse_context & ctx) {
		return ctx.begin(); // no custom format spec, just return
	}

	auto format(const String & s, std::format_context & ctx) const {
		std::string_view view(
			reinterpret_cast<const char *>(s.ptr), s.size
		);
		return std::format_to(ctx.out(), "{}", view);
	}
};

template <> struct std::formatter<syntax::Token> {
	// parse() handles format spec like {:.2f}
	constexpr auto parse(std::format_parse_context & ctx) {
		return ctx.begin(); // no custom format spec, just return
	}

	auto format(
		const syntax::Token & token, std::format_context & ctx
	) const {
		return std::format_to(
			ctx.out(), "({}, {}, line: {}, column: {})", token.kind,
			token.value, token.line, token.column
		);
	}
};
