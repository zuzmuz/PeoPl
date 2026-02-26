use crate::syntax::tokenizer::{self, TokenKind, Tokenizer};
// enum Op {
//
// }

#[derive(Clone, Debug, PartialEq, Eq)]
enum ExpressionKind {
    // literals
    IntLiteral(u64),
    // FloatLiteral,
    // ImaginaryLiteral,
    // StringLiteral,
    // Identifier,
    // Special,

    // primary
    // Unary(),
    //
    // Binary,
    // Call,
    // Access,
    //
    // Tagged,
    //
    // Empty,
    // Invalid,
}

struct Expression {
    kind: ExpressionKind,
}

struct Ast<'a> {
    expression_list: Vec<&'a Expression>,
}

struct Parser<'a> {
    tokens: Vec<tokenizer::Token<'a>>,
    expressions: Vec<Expression>,

    cursor: usize,
}

impl<'a> Parser<'a> {
    pub fn new(source: &'a str) -> Self {
        let mut tokenizer = Tokenizer::new(source);

        let mut tokens: Vec<tokenizer::Token> =
            Vec::with_capacity(source.len() / 8);

        let mut token = tokenizer.next_token();
        tokens.push(token.clone());
        while token.kind != TokenKind::Eof {
            token = tokenizer.next_token();
            tokens.push(token.clone());
        }
        let tokens_len = tokens.len();
        Parser {
            tokens,
            expressions: Vec::with_capacity(tokens_len / 4),
            cursor: 0,
        }
    }

    pub fn parse(&mut self) -> Ast {
        Ast {
            expression_list: self
                .parse_expression_list(tokenizer::TokenKind::Eof),
        }
    }

    fn parse_expression_list(
        &mut self,
        end_token: tokenizer::TokenKind,
    ) -> Vec<&Expression> {
        
        panic!()
    }
}
