use crate::syntax::tokenizer;
// // enum Op {
// //
// // }
//
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

#[derive(Debug)]
struct Expression {
    kind: ExpressionKind,
}

#[derive(Debug)]
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

        let tokens = tokenizer::lex_source(source);
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
                .parse_expression_list(tokenizer::Token::Eof),
        }
    }

    fn parse_expression_list(
        &mut self,
        end_token: tokenizer::Token,
    ) -> Vec<&Expression> {
        // parsing first expression of the list
        let expr = self.parse_complex_expression();
        self.expressions.push(expr);
        self.cursor += 1;

        while self.tokens[self.cursor] != end_token {
            let mut num_commas = 0;
            loop {
                if self.tokens[self.cursor] == tokenizer::Token::Comma {
                    num_commas += 1;
                    if num_commas > 1 {
                        panic!("no more the 2 commas allowed");
                    }
                }
            }
        }
        panic!()
    }

    fn parse_complex_expression(
        &mut self) -> Expression {
        panic!();
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn numbers() {
        let test_string = "3\n10\0x12";

        let mut parser = Parser::new(test_string);

        // let ast = parser.parse();

        // println!("the ast {:#?}", ast);
    }
}
