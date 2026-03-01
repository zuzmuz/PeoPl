use crate::syntax::{
    self,
    tokenizer::{self, Token},
};
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
    fn is_binary(&self) -> bool {
        match self {
            Operator::Not | Operator::Bnot => false,
            _ => true,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Container {
    Paren,
    Bracket,
    Brace,
    File,
}

impl<'a> Token<'a> {
    fn precedence(&self) -> i8 {
        match self {
            // scoping
            Token::Backslash => 100,

            Token::Dot => 50,

            Token::Lparen | Token::Lbracket | Token::Lbrace => 40,

            Token::Bnot => 31,
            Token::KwordNot => 30,

            Token::OpExponent => 20,
            Token::OpTimes | Token::OpBy | Token::OpMod => 19,

            Token::OpPlus | Token::OpMinus => 18,

            Token::Lshift | Token::Rshift => 16,

            Token::Band => 13,
            Token::Bxor => 12,
            Token::Bor => 11,

            Token::OpEq
            | Token::OpGe
            | Token::OpGt
            | Token::OpLe
            | Token::OpLt => 10,

            Token::KwordAnd => 9,
            Token::KwordOr => 8,

            Token::Pipe => 5,

            Token::Colon => 2,
            Token::Comma => 1,

            Token::DecLiteral(_)
            | Token::HexLiteral(_)
            | Token::OctLiteral(_)
            | Token::BinLiteral(_)
            | Token::FloatLiteral(_)
            | Token::ImaginaryLiteral(_)
            | Token::StringLiteral(_)
            | Token::Special
            | Token::Identifier(_) => -1,

            Token::Propagate => todo!(),
            Token::Bar => todo!(),
            Token::Appostrophe => todo!(),
            Token::Positional => todo!(),
            Token::Comment => todo!(),
            // Token::NewLine => todo!(),
            Token::Binding => todo!(),
            Token::Arrow => todo!(),
            Token::KwordIf => todo!(),
            Token::KwordComp => todo!(),
            Token::KwordFn => todo!(),

            Token::Eof | Token::Rparen | Token::Rbracket | Token::Rbrace => -2,
        }
    }

    fn operator(&self) -> Option<Operator> {
        match self {
            Token::OpExponent => Some(Operator::Exponent),
            Token::OpTimes => Some(Operator::Times),
            Token::OpBy => Some(Operator::By),
            Token::OpMod => Some(Operator::Mod),
            Token::OpPlus => Some(Operator::Plus),
            Token::OpMinus => Some(Operator::Minus),
            Token::Lshift => Some(Operator::Lshift),
            Token::Rshift => Some(Operator::Rshift),
            Token::Band => Some(Operator::Band),
            Token::Bor => Some(Operator::Bor),
            Token::Bxor => Some(Operator::Bxor),
            Token::OpEq => Some(Operator::Eq),
            Token::OpGe => Some(Operator::Ge),
            Token::OpGt => Some(Operator::Gt),
            Token::OpLe => Some(Operator::Le),
            Token::OpLt => Some(Operator::Lt),
            Token::KwordAnd => Some(Operator::And),
            Token::KwordOr => Some(Operator::Or),
            Token::KwordNot => Some(Operator::Not),
            Token::Bnot => Some(Operator::Bnot),
            _ => None,
        }
    }

    fn opening(&self) -> Option<Container> {
        match self {
            Token::Lparen => Some(Container::Paren),
            Token::Lbracket => Some(Container::Bracket),
            Token::Lbrace => Some(Container::Brace),
            _ => None,
        }
    }

    fn closing(&self) -> Option<Container> {
        match self {
            Token::Rparen => Some(Container::Paren),
            Token::Rbracket => Some(Container::Bracket),
            Token::Rbrace => Some(Container::Brace),
            Token::Eof => Some(Container::File),
            _ => None,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
struct Identifier<'a> {
    id: &'a str,
}

#[derive(Clone, Debug, PartialEq)]
pub enum Expression<'a> {
    // literals
    IntLiteral(u64),
    FloatLiteral(f64),
    ImaginaryLiteral(f64),
    StringLiteral(&'a str),
    Identifier(&'a str),
    // QualifiedIdentifier(Vec<&'a str>),
    // Special,

    // primary
    Unary(Operator, Box<Expression<'a>>),
    Binary(Operator, Box<Expression<'a>>, Box<Expression<'a>>),

    List(Container, Vec<Expression<'a>>),
    // Call,
    Access(Box<Expression<'a>>, Identifier<'a>),
    //
    Tagged(Identifier<'a>, Box<Expression<'a>>),
    //
    Empty,
    // Invalid,
}

pub struct Parser<'a> {
    tokens: Vec<Token<'a>>,
    cursor: usize,
}

impl<'a> Parser<'a> {
    pub fn new(source: &'a str) -> Self {
        let tokens = tokenizer::lex_source(source);
        Parser { tokens, cursor: 0 }
    }

    pub fn parse(&mut self) -> Expression<'a> {
        let expression = self.parse_primary_expression(Container::File);
        self.continue_parsing(0, expression, Container::File)
    }

    fn continue_parsing(
        &mut self,
        last_precedence: i8,
        last_expression: Expression<'a>,
        container: Container,
    ) -> Expression<'a> {
        let mut last_expression = last_expression;
        loop {
            println!("Last {:#?}", last_expression);
            let operator_token = self.tokens[self.cursor + 1];
            println!("Current token {:?}", operator_token);

            let current_precedence = operator_token.precedence();

            if current_precedence == -1 {
                panic!("syntax error");
            }

            if let Some(container_closing) = operator_token.closing() {
                println!(
                    "closing the token {:?}, from {:?}",
                    container_closing, operator_token
                );
                if container_closing == container {
                    // closing expression
                    return last_expression;
                } else {
                    todo!("illegal closing");
                }
            }

            if current_precedence < last_precedence {
                return last_expression;
            }

            self.cursor += 2;

            let mut next_expression = self.parse_primary_expression(container);

            let next_precedence = self.tokens[self.cursor + 1].precedence();

            if current_precedence < next_precedence {
                next_expression = self.continue_parsing(
                    current_precedence + 1,
                    next_expression,
                    container,
                );
            }

            if operator_token == Token::Comma {
                if let Expression::List(cont, vec) = last_expression {
                    let mut vec = vec;
                    vec.push(next_expression);
                    last_expression = Expression::List(cont, vec);
                } else {
                    last_expression = Expression::List(
                        container,
                        vec![last_expression, next_expression],
                    )
                }
            } else if operator_token == Token::Colon {
                match last_expression {
                    Expression::Identifier(ident) => {
                        last_expression = Expression::Tagged(
                            Identifier { id: ident },
                            Box::new(next_expression),
                        )
                    }
                    _ => todo!(
                        "tagged expression requires lhs to be an identifier"
                    ),
                }
            } else if let Some(operator) = operator_token.operator() {
                if operator.is_binary() {
                    last_expression = Expression::Binary(
                        operator,
                        Box::new(last_expression),
                        Box::new(next_expression),
                    )
                } else {
                    todo!("syntax error illegal unary operator");
                }
            } else if operator_token == Token::Backslash {
                todo!("qualified identifiers");
            } else if operator_token == Token::Dot {
                match next_expression {
                    Expression::Identifier(ident) => {
                        last_expression = Expression::Access(
                            Box::new(last_expression),
                            Identifier { id: ident },
                        );
                    }
                    _ => todo!(
                        "access expression requires rhs to be an identifier"
                    ),
                }
            }
        }
    }

    /// PrimaryExpression
    ///   : Literal
    ///   | Identifier
    ///   | ParenthesizedExpression
    ///   | Unary
    ///   ;
    ///
    fn parse_primary_expression(
        &mut self,
        container: Container,
    ) -> Expression<'a> {
        println!("Parsing Literal {:?}", self.tokens[self.cursor]);
        match &self.tokens[self.cursor] {
            Token::DecLiteral(value)
            | Token::HexLiteral(value)
            | Token::OctLiteral(value)
            | Token::BinLiteral(value) => Expression::IntLiteral(*value),
            Token::FloatLiteral(value) => Expression::FloatLiteral(*value),
            Token::ImaginaryLiteral(value) => {
                Expression::ImaginaryLiteral(*value)
            }
            Token::StringLiteral(value) => Expression::StringLiteral(value),
            Token::Identifier(value) => Expression::Identifier(value),
            &token => {
                if let Some(container_opening) = token.opening() {
                    self.cursor += 1;
                    let expression =
                        self.parse_primary_expression(container_opening);
                    let inside_expression =
                        self.continue_parsing(0, expression, container_opening);
                    self.cursor += 1;
                    inside_expression
                } else if let Some(container_closing) = token.closing() {
                    if container_closing == container {
                        self.cursor -= 1;
                        Expression::Empty
                    } else {
                        todo!("Wrong closing");
                    }
                } else if let Some(operator) = token.operator() {
                    self.cursor += 1;
                    let expression = self.parse_primary_expression(container);
                    let continued_expression = self.continue_parsing(
                        token.precedence() + 1,
                        expression,
                        container,
                    );
                    Expression::Unary(operator, Box::new(continued_expression))
                } else {
                    todo!("check if more primary expression types");
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn numbers() {
        let source = "1, 0x12, 3.4";

        let mut parser = Parser::new(source);

        let ast = parser.parse();

        let reference = Expression::List(
            Container::File,
            vec![
                Expression::IntLiteral(1),
                Expression::IntLiteral(18),
                Expression::FloatLiteral(3.4),
            ],
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn basic() {
        let source = "
            c: - 1 * 4 > 3 - 2 and value = \"string\"
        ";

        let mut parser = Parser::new(source);
        let ast = parser.parse();
        let reference = Expression::Tagged(
            Identifier { id: "c" },
            Box::new(Expression::Binary(
                Operator::And,
                Box::new(Expression::Binary(
                    Operator::Gt,
                    Box::new(Expression::Unary(
                        Operator::Minus,
                        Box::new(Expression::Binary(
                            Operator::Times,
                            Box::new(Expression::IntLiteral(1)),
                            Box::new(Expression::IntLiteral(4)),
                        )),
                    )),
                    Box::new(Expression::Binary(
                        Operator::Minus,
                        Box::new(Expression::IntLiteral(3)),
                        Box::new(Expression::IntLiteral(2)),
                    )),
                )),
                // value = "string"
                Box::new(Expression::Binary(
                    Operator::Eq,
                    Box::new(Expression::Identifier("value")),
                    Box::new(Expression::StringLiteral("string")),
                )),
            )),
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn member_access() {
        let source = "
            v: - s.a ^ 2 * 3 + s.b
        ";

        let mut parser = Parser::new(source);

        let ast = parser.parse();
        let reference = Expression::Tagged(
            Identifier { id: "v" },
            Box::new(Expression::Binary(
                Operator::Plus,
                Box::new(Expression::Unary(
                    Operator::Minus,
                    Box::new(Expression::Binary(
                        Operator::Times,
                        Box::new(Expression::Binary(
                            Operator::Exponent,
                            Box::new(Expression::Access(
                                Box::new(Expression::Identifier("s")),
                                Identifier { id: "a" },
                            )),
                            Box::new(Expression::IntLiteral(2)),
                        )),
                        Box::new(Expression::IntLiteral(3)),
                    )),
                )),
                Box::new(Expression::Access(
                    Box::new(Expression::Identifier("s")),
                    Identifier { id: "b" },
                )),
            )),
        );

        assert_eq!(ast, reference);
    }
}
