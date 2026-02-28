use crate::syntax::tokenizer;
// // enum Op {
// //
// // }
//
//
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Operator {
    Exponent,
    Times,
    By,
    Mod,
    Plus,
    Minus,
    Lshift,
    Rshift,
    Band,
    Bor,
    Bxor,
    Eq,
    Ge,
    Gt,
    Le,
    Lt,
    And,
    Or,

    Not,
    Bnot,
}

impl Operator {
    // fn binary_precedence(self) -> i8 {
    //     match self {
    //         Operator::Exponent => 10,
    //         Operator::Times | Operator::By | Operator::Mod => 9,
    //         Operator::Plus | Operator::Minus => 8,
    //         Operator::Lshift | Operator::Rshift => 7,
    //         Operator::Band => 6,
    //         Operator::Bor => 5,
    //         Operator::Bxor => 4,
    //         Operator::Eq
    //         | Operator::Ge
    //         | Operator::Gt
    //         | Operator::Le
    //         | Operator::Lt => 3,
    //         Operator::And => 2,
    //         Operator::Or => 1,
    //         _ => -1,
    //     }
    // }
}

impl<'a> tokenizer::Token<'a> {
    fn precedence(&self) -> i8 {
        match self {
            tokenizer::Token::Dot => 50,

            tokenizer::Token::Lparen
            | tokenizer::Token::Lbracket
            | tokenizer::Token::Lbrace => 40,

            tokenizer::Token::Bnot => 31,
            tokenizer::Token::KwordNot => 30,

            tokenizer::Token::OpExponent => 20,
            tokenizer::Token::OpTimes
            | tokenizer::Token::OpBy
            | tokenizer::Token::OpMod => 19,

            tokenizer::Token::OpPlus | tokenizer::Token::OpMinus => 18,

            tokenizer::Token::Lshift | tokenizer::Token::Rshift => 16,

            tokenizer::Token::Band => 13,
            tokenizer::Token::Bxor => 12,
            tokenizer::Token::Bor => 11,

            tokenizer::Token::OpEq
            | tokenizer::Token::OpGe
            | tokenizer::Token::OpGt
            | tokenizer::Token::OpLe
            | tokenizer::Token::OpLt => 10,

            tokenizer::Token::KwordAnd => 9,
            tokenizer::Token::KwordOr => 8,

            tokenizer::Token::Pipe => 5,

            tokenizer::Token::Colon => 2,
            tokenizer::Token::Comma => 1,

            tokenizer::Token::Rparen => todo!(),
            tokenizer::Token::Rbracket => todo!(),
            tokenizer::Token::Rbrace => todo!(),

            tokenizer::Token::DecLiteral(_) => todo!(),
            tokenizer::Token::HexLiteral(_) => todo!(),
            tokenizer::Token::OctLiteral(_) => todo!(),
            tokenizer::Token::BinLiteral(_) => todo!(),
            tokenizer::Token::FloatLiteral(_) => todo!(),
            tokenizer::Token::ImaginaryLiteral(_) => todo!(),
            tokenizer::Token::StringLiteral(_) => todo!(),
            tokenizer::Token::Special => todo!(),
            tokenizer::Token::KwordIf => todo!(),
            tokenizer::Token::KwordComp => todo!(),
            tokenizer::Token::KwordFn => todo!(),

            tokenizer::Token::Identifier(_) => todo!(),
            tokenizer::Token::Propagate => todo!(),

            tokenizer::Token::Bar => todo!(),
            tokenizer::Token::Backslash => todo!(),
            tokenizer::Token::Appostrophe => todo!(),
            tokenizer::Token::Arrow => todo!(),
            tokenizer::Token::Binding => todo!(),
            tokenizer::Token::Positional => todo!(),
            tokenizer::Token::Comment => todo!(),
            tokenizer::Token::NewLine => todo!(),
            tokenizer::Token::Eof => todo!(),
        }
    }

    fn operator(&self) -> Option<Operator> {
        match &self {
            tokenizer::Token::OpExponent => Some(Operator::Exponent),
            tokenizer::Token::OpTimes => Some(Operator::Times),
            tokenizer::Token::OpBy => Some(Operator::By),
            tokenizer::Token::OpMod => Some(Operator::Mod),
            tokenizer::Token::OpPlus => Some(Operator::Plus),
            tokenizer::Token::OpMinus => Some(Operator::Minus),
            tokenizer::Token::Lshift => Some(Operator::Lshift),
            tokenizer::Token::Rshift => Some(Operator::Rshift),
            tokenizer::Token::Band => Some(Operator::Band),
            tokenizer::Token::Bor => Some(Operator::Bor),
            tokenizer::Token::Bxor => Some(Operator::Bxor),
            tokenizer::Token::OpEq => Some(Operator::Eq),
            tokenizer::Token::OpGe => Some(Operator::Ge),
            tokenizer::Token::OpGt => Some(Operator::Gt),
            tokenizer::Token::OpLe => Some(Operator::Le),
            tokenizer::Token::OpLt => Some(Operator::Lt),
            tokenizer::Token::KwordAnd => Some(Operator::And),
            tokenizer::Token::KwordOr => Some(Operator::Or),
            tokenizer::Token::KwordNot => Some(Operator::Not),
            tokenizer::Token::Bnot => Some(Operator::Bnot),
            _ => None,
        }
    }

    fn is_dot(&self) -> bool {
        *self == tokenizer::Token::Dot
    }
    fn is_lparen(&self) -> bool {
        *self == tokenizer::Token::Lparen
    }
    fn is_lbracket(&self) -> bool {
        *self == tokenizer::Token::Lbracket
    }
    fn is_lbrace(&self) -> bool {
        *self == tokenizer::Token::Lbrace
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum Expression<'a> {
    // literals
    IntLiteral(u64),
    FloatLiteral(f64),
    ImaginaryLiteral(f64),
    StringLiteral(&'a str),
    Identifier(&'a str),
    // Special,

    // primary
    // Unary(),
    //
    Binary(Operator, usize, usize),

    List(Vec<usize>),
    // Call,
    // Access,
    //
    // Tagged,
    //
    // Empty,
    // Invalid,
}

pub struct Parser<'a> {
    tokens: Vec<tokenizer::Token<'a>>,
    pub expressions: Vec<Expression<'a>>,

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

    pub fn parse(&mut self) -> Expression<'a> {
        let expr = self.parse_primary_expression();

        return expr;
    }

    // fn parse_expression_list(
    //     &mut self,
    //     end_token: tokenizer::Token,
    // ) -> Vec<usize> {
    //     // parsing first expression of the list
    //     let mut expressions: Vec<usize> = Vec::new();
    //     let expr = self.parse_complex_expression();
    //     println!("Complex expression parsed: {:#?}", expr);
    //     expressions.push(self.expressions.len());
    //     self.expressions.push(expr);
    //     self.cursor += 1;
    //
    //     while self.tokens[self.cursor] != end_token {
    //         println!("next token {:?}", self.tokens[self.cursor]);
    //         while self.tokens[self.cursor] == tokenizer::Token::Comma
    //             || self.tokens[self.cursor] == tokenizer::Token::NewLine
    //         {
    //             self.cursor += 1;
    //         }
    //         let expr = self.parse_complex_expression();
    //         println!("Complex expression parsed: {:#?}", expr);
    //         expressions.push(self.expressions.len());
    //         self.expressions.push(expr);
    //     }
    //     return expressions;
    // }

    /// ComplexExpression
    /// : TaggedExpression
    /// | BasicExpression
    /// ;
    // fn parse_complex_expression(&mut self) -> Expression<'a> {
    //     match self.tokens[self.cursor] {
    //         tokenizer::Token::Identifier(identifier) => {
    //             if self.tokens[self.cursor + 1] == tokenizer::Token::Colon {
    //                 self.cursor += 2;
    //                 // TODO: make tagged
    //                 panic!()
    //             } else {
    //                 self.parse_basic_expression()
    //             }
    //         }
    //         _ => self.parse_basic_expression(),
    //     }
    // }

    /// BasicExpression
    /// : PrimaryExpression extension
    /// ;
    // fn parse_basic_expression(&mut self) -> Expression<'a> {
    //     println!("Parsing basic expression");
    //     let lhs_expr = self.parse_primary_expression();
    //
    //     self.parse_extended_expression(0, lhs_expr)
    // }

    // fn parse_extended_expression(
    //     &mut self,
    //     last_precedence: i8,
    //     lhs_expr: Expression<'a>,
    // ) -> Expression<'a> {
    //     let mut lhs_expr = lhs_expr;
    //     loop {
    //         println!("lhs {:#?}", lhs_expr);
    //         println!("Binop token {:?}", self.tokens[self.cursor]);
    //         if self.tokens[self.cursor].is_dot() {
    //             // Access expression
    //             // TODO: handle access
    //             todo!("handle access");
    //         } else if self.tokens[self.cursor].is_lparen() {
    //             // call() expression
    //             // TODO: handle paren call
    //             todo!("handle paren call");
    //         } else if self.tokens[self.cursor].is_lbracket() {
    //             // call[] expression
    //             // TODO: handle bracket call
    //             todo!("handle bracket call");
    //         } else if self.tokens[self.cursor].is_lbrace() {
    //             // call{} expression
    //             // TODO: handle brace call
    //             todo!("handle brace call");
    //         } else if let Some(operator) = self.tokens[self.cursor].operator() {
    //             // binary expression
    //             let current_precedence = operator.binary_precedence();
    //             if current_precedence < last_precedence {
    //                 return lhs_expr;
    //             }
    //
    //             self.cursor += 1;
    //             let mut rhs_expr = self.parse_primary_expression();
    //
    //             let next_precedence = self.tokens[self.cursor].precedence();
    //             if current_precedence < next_precedence {
    //                 rhs_expr = self.parse_extended_expression(
    //                     current_precedence + 1,
    //                     rhs_expr,
    //                 );
    //             }
    //             let expr_size = self.expressions.len();
    //             self.expressions.push(lhs_expr);
    //             self.expressions.push(rhs_expr);
    //
    //             lhs_expr =
    //                 Expression::Binary(operator, expr_size, expr_size + 1);
    //         } else {
    //             // next token is not an operator and we should stop
    //             // TODO: not really cause if it's a new line we might have to continue on the next
    //             // line
    //             return lhs_expr;
    //         }
    //     }
    // }

    /// PrimaryExpression
    ///   : Literal
    ///   | Identifier
    ///   | ParenthesizedExpression
    ///   | Positional
    ///   ;
    ///
    fn parse_primary_expression(&mut self) -> Expression<'a> {
        println!("Parsing Literal {:?}", self.tokens[self.cursor]);
        match &self.tokens[self.cursor] {
            tokenizer::Token::DecLiteral(value)
            | tokenizer::Token::HexLiteral(value)
            | tokenizer::Token::OctLiteral(value)
            | tokenizer::Token::BinLiteral(value) => {
                Expression::IntLiteral(*value)
            }
            tokenizer::Token::FloatLiteral(value) => {
                Expression::FloatLiteral(*value)
            }
            tokenizer::Token::ImaginaryLiteral(value) => {
                Expression::ImaginaryLiteral(*value)
            }
            tokenizer::Token::StringLiteral(value) => {
                Expression::StringLiteral(value)
            }
            tokenizer::Token::Identifier(value) => {
                Expression::Identifier(value)
            }
            _ => todo!(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn numbers() {
        let test_string = "3\n10\0x12";

        let mut parser = Parser::new(test_string);

        let ast = parser.parse();

        // println!("the ast {:#?}", ast);
    }
}
