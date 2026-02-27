// use crate::syntax::tokenizer::{self, TokenKind, Tokenizer};
// // enum Op {
// //
// // }
//
// #[derive(Clone, Debug, PartialEq, Eq)]
// enum ExpressionKind {
//     // literals
//     IntLiteral(u64),
//     // FloatLiteral,
//     // ImaginaryLiteral,
//     // StringLiteral,
//     // Identifier,
//     // Special,
//
//     // primary
//     // Unary(),
//     //
//     // Binary,
//     // Call,
//     // Access,
//     //
//     // Tagged,
//     //
//     // Empty,
//     // Invalid,
// }
//
// #[derive(Debug)]
// struct Expression {
//     kind: ExpressionKind,
// }
//
// #[derive(Debug)]
// struct Ast<'a> {
//     expression_list: Vec<&'a Expression>,
// }
//
// struct Parser<'a> {
//     tokens: Vec<tokenizer::Token<'a>>,
//     expressions: Vec<Expression>,
//
//     cursor: usize,
// }
//
// impl<'a> Parser<'a> {
//     pub fn new(source: &'a str) -> Self {
//         let mut tokenizer = Tokenizer::new(source);
//
//         let mut tokens: Vec<tokenizer::Token> =
//             Vec::with_capacity(source.len() / 8);
//
//         let mut token = tokenizer.next_token();
//         tokens.push(token.clone());
//         while token.kind != TokenKind::Eof {
//             token = tokenizer.next_token();
//             tokens.push(token.clone());
//         }
//         let tokens_len = tokens.len();
//         Parser {
//             tokens,
//             expressions: Vec::with_capacity(tokens_len / 4),
//             cursor: 0,
//         }
//     }
//
//     pub fn parse(&mut self) -> Ast {
//         Ast {
//             expression_list: self
//                 .parse_expression_list(tokenizer::TokenKind::Eof),
//         }
//     }
//
//     fn parse_expression_list(
//         &mut self,
//         end_token: tokenizer::TokenKind,
//     ) -> Vec<&Expression> {
//         // parsing first expression of the list
//         let expr = self.parse_complex_expression();
//         self.expressions.push(expr);
//         self.cursor += 1;
//
//         while self.tokens[self.cursor].kind != end_token {
//             let mut num_commas = 0;
//             loop {
//                 if self.tokens[self.cursor].kind == tokenizer::TokenKind::Comma {
//                     num_commas += 1;
//                     if num_commas > 1 {
//                         panic!("no more the 2 commas allowed");
//                     }
//                 }
//             }
//         }
//         panic!()
//     }
//
//     fn parse_complex_expression(
//         &mut self) -> Expression {
//         panic!();
//     }
// }
//
//
// #[cfg(test)]
// mod tests {
//     use super::*;
//
//     #[test]
//     fn numbers() {
//         let test_string = "3\n10\0x12";
//
//         let mut parser = Parser::new(test_string);
//
//         // let ast = parser.parse();
//
//         // println!("the ast {:#?}", ast);
//     }
// }
