use std::fmt::format;

use crate::syntax::tokenizer::{self, Token};

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
    Pipe,

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
    Guard,
    BranchBody,
    File,
}

impl<'a> Token<'a> {
    fn precedence(&self) -> i8 {
        match self {
            // scoping
            Token::Backslash => 100,

            Token::Dot => 50,

            Token::Lparen
            | Token::Lbracket
            | Token::Lbrace
            | Token::Rparen
            | Token::Rbracket
            | Token::Rbrace
            | Token::Bar
            | Token::KwordIf
            | Token::Eof => 40,

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
            | Token::KwordFn
            | Token::Arrow
            | Token::Identifier(_)
            | Token::Positional(_)
            | Token::Binding(_) => -1,

            Token::Propagate => todo!(),
            Token::Appostrophe => todo!(),
            Token::KwordComp => todo!(),

            Token::NewLine | Token::Comment => -3,
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
            Token::Pipe => Some(Operator::Pipe),
            _ => None,
        }
    }

    /// Bar is not considered an opening container, because it has special semantics
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
            Token::Bar => Some(Container::Guard),
            Token::KwordIf => Some(Container::Guard), // if closes guard expression
            Token::Eof => Some(Container::File),
            _ => None,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Identifier<'a>(&'a str);

#[derive(Clone, Debug, PartialEq)]
pub struct Branch<'a> {
    match_expression: Expression<'a>,
    guard_expression: Option<Expression<'a>>,
    body: Expression<'a>,
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
    Special,
    Positional(&'a str),
    Binding(&'a str),

    // primary
    Unary(Operator, Box<Expression<'a>>),
    Binary(Operator, Box<Expression<'a>>, Box<Expression<'a>>),

    List(Container, Vec<Expression<'a>>),
    Call(Container, Box<Expression<'a>>, Vec<Expression<'a>>),
    Access(Box<Expression<'a>>, Identifier<'a>),

    Tagged(Identifier<'a>, Box<Expression<'a>>),

    Branched(Vec<Branch<'a>>),

    Function(Vec<Expression<'a>>, Box<Expression<'a>>),

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
        self.parse_complex_expression(Container::File)
    }

    fn skip_to_next_valid_token(&mut self) {
        while self.tokens[self.cursor].precedence() == -3 {
            self.cursor += 1;
        }
    }

    fn advance(&mut self) {
        println!(
            "advancing from {:?}: {:?}",
            self.cursor, self.tokens[self.cursor]
        );

        self.cursor += 1;
        self.skip_to_next_valid_token();

        println!(
            "advancing to {:?}: {:?}",
            self.cursor, self.tokens[self.cursor]
        );
    }

    fn peek_next_token(&self) -> Token<'a> {
        let mut current_cursor = self.cursor;

        current_cursor += 1;
        while self.tokens[self.cursor].precedence() == -3 {
            current_cursor += 1;
        }
        self.tokens[current_cursor]
    }

    /// : Branched
    /// | PrimaryExpression
    fn parse_complex_expression(
        &mut self,
        container: Container,
    ) -> Expression<'a> {
        self.skip_to_next_valid_token();
        match &self.tokens[self.cursor] {
            Token::Bar => {
                let mut branches: Vec<Branch<'a>> = Vec::new();

                loop {
                    self.advance();
                    let expression =
                        self.parse_primary_expression(Container::Guard);
                    let continued_expression =
                        self.continue_parsing(0, expression, Container::Guard);
                    self.advance();

                    let (match_expression, guard_expression): (
                        Expression<'a>,
                        Option<Expression<'a>>,
                    ) = match self.tokens[self.cursor] {
                        Token::Bar => (continued_expression, None),
                        Token::KwordIf => {
                            self.advance();

                            let expression =
                                self.parse_primary_expression(Container::Guard);
                            let guard_expression = self.continue_parsing(
                                0,
                                expression,
                                Container::Guard,
                            );
                            self.advance();

                            (continued_expression, Some(guard_expression))
                        }
                        _ => {
                            todo!(
                                "this should not happen but handle error anyways"
                            );
                        }
                    };

                    self.advance();

                    let expression =
                        self.parse_primary_expression(Container::BranchBody);
                    let continued_expression = self.continue_parsing(
                        0,
                        expression,
                        Container::BranchBody,
                    );

                    if let Some(closing_container) =
                        self.peek_next_token().closing()
                    {
                        branches.push(Branch {
                            match_expression,
                            guard_expression,
                            body: continued_expression,
                        });
                        if closing_container == Container::Guard {
                            self.advance();
                            continue;
                        } else if closing_container == container {
                            break;
                        }
                    } else {
                        todo!("unreachable state");
                    }
                }
                Expression::Branched(branches)
            }
            _ => {
                let primary_expression =
                    self.parse_primary_expression(container);
                self.continue_parsing(0, primary_expression, container)
            }
        }
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
            let operator_token = self.peek_next_token();
            println!("Current token {:?}", operator_token);

            let current_precedence = operator_token.precedence();

            if current_precedence == -1 {
                // expecting operator token got something else
                todo!("handle syntax error properly");
            }

            if let Some(container_closing) = operator_token.closing() {
                println!(
                    "closing the token {:?}, from {:?} container {:?}",
                    container_closing, operator_token, container,
                );
                if container_closing == container {
                    // closing expression
                    return last_expression;
                } else if container == Container::BranchBody {
                    return last_expression;
                } else {
                    // Got unexpected closing token
                    todo!("illegal closing");
                }
            }

            println!("precc {current_precedence} {last_precedence}");
            if current_precedence < last_precedence {
                // past expression chain had higher precedence
                // stop parsing and return expression
                return last_expression;
            }

            if let Some(opening_container) = operator_token.opening() {
                // Found opening, it is a call expressions
                // self.cursor += 2; // Skip opening and start parsing complex expression

                self.advance();
                self.advance();
                // This might not need to be a complex expression
                let fields_expression =
                    self.parse_complex_expression(opening_container);

                let fields = if let Expression::List(_, vec) = fields_expression
                {
                    // if fields are already an expression list return them
                    vec
                } else {
                    // otherwise crreate vector
                    vec![fields_expression]
                };

                self.advance();

                // Update last expression as a call expression and continue parsing
                last_expression = Expression::Call(
                    opening_container,
                    Box::new(last_expression),
                    fields,
                );
                continue;
            }

            // if not call expression

            self.advance();
            self.advance();

            let mut next_expression = self.parse_primary_expression(container);

            // let next_precedence = self.peek_next_token().precedence();
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
                            Identifier(ident),
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
                            Identifier(ident),
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
            Token::Positional(value) => Expression::Positional(value),
            Token::Binding(value) => Expression::Binding(value),
            Token::Special => Expression::Special,
            Token::Identifier(value) => Expression::Identifier(value),
            Token::KwordIf => {
                todo!("handle empty match expression");
            }
            Token::Bar => {
                todo!("handle error no bars are allowed");
            }
            Token::KwordFn => {
                self.advance();
                if self.tokens[self.cursor] != Token::Lparen {
                    todo!("fn should have parent opening")
                } else {
                    let function_params =
                        self.parse_primary_expression(container);
                    self.advance();
                    if self.tokens[self.cursor] == Token::Arrow {
                        self.advance();
                        let expression =
                            self.parse_primary_expression(container);
                        let continued_expression =
                            self.continue_parsing(0, expression, container);
                        Expression::Function(
                            vec![function_params],
                            Box::new(continued_expression),
                        )
                    } else {
                        todo!("need arrow for function")
                    }
                }
            }
            &token => {
                if let Some(container_opening) = token.opening() {
                    self.advance();
                    let inside_expression =
                        self.parse_complex_expression(container_opening);
                    self.advance();
                    inside_expression
                } else if let Some(container_closing) = token.closing() {
                    if container_closing == container {
                        self.cursor -= 1;
                        Expression::Empty
                    } else if container == Container::BranchBody {
                        todo!("empty branch body is illegal");
                    } else {
                        todo!("Wrong closing");
                    }
                } else if let Some(operator) = token.operator() {
                    self.advance();
                    let expression = self.parse_primary_expression(container);
                    let continued_expression = self.continue_parsing(
                        token.precedence() + 1,
                        expression,
                        container,
                    );
                    Expression::Unary(operator, Box::new(continued_expression))
                } else if Token::NewLine == token || Token::Comment == token {
                    self.advance();
                    self.parse_primary_expression(container)
                } else {
                    todo!("check if more primary expression types");
                }
            }
        }
    }
}

enum Connector {
    Last,
    NotLast,
}

impl Connector {
    // TODO: use proper str instead of String
    fn display(&self) -> String {
        match self {
            Self::Last => "└─ ".to_string(),
            Self::NotLast => "├─ ".to_string(),
        }
    }

    fn child_prefix(&self) -> String {
        match self {
            Self::Last => "   ".to_string(),
            Self::NotLast => "│  ".to_string(),
        }
    }
}

trait ASTDisplay {
    fn display_ast(
        &self,
        prefix: String,
        connector: Connector,
        extra: String,
        descriptions: &mut Vec<String>,
    );
}

impl<'a> ASTDisplay for Expression<'a> {
    fn display_ast(
        &self,
        prefix: String,
        connector: Connector,
        extra: String,
        descriptions: &mut Vec<String>,
    ) {
        let child_prefix = format!("{}{}", prefix, connector.child_prefix());
        match self {
            Expression::IntLiteral(_) => todo!(),
            Expression::FloatLiteral(_) => todo!(),
            Expression::ImaginaryLiteral(_) => todo!(),
            Expression::StringLiteral(value) => {
                descriptions.push(format!(
                    "{}{}{}{}: {}",
                    prefix,
                    connector.display(),
                    extra,
                    "Literal",
                    value
                ));
                // "\(prefix)\(connector)\(extra)\("Literal".colored(.cyan)) \(self.location): \(value.debugDescription.colored(.green))"
                // )
            }
            Expression::Identifier(_) => todo!(),
            Expression::Special => todo!(),
            Expression::Positional(_) => todo!(),
            Expression::Binding(_) => todo!(),
            Expression::Unary(operator, expression) => todo!(),
            Expression::Binary(operator, expression, expression1) => todo!(),
            Expression::List(container, expressions) => {
                descriptions.push(format!(
                    "{}{}Arguments",
                    child_prefix,
                    Connector::Last.display()
                ));
                for (index, expression) in expressions.iter().enumerate() {
                    let is_last_arg = index == expressions.len() - 1;
                    expression.display_ast(
                        format!(
                            "{}{}",
                            child_prefix,
                            Connector::Last.child_prefix()
                        ),
                        if is_last_arg {
                            Connector::Last
                        } else {
                            Connector::NotLast
                        },
                        format!("#{}", index),
                        descriptions,
                    );
                }
            }
            Expression::Call(container, prefix, fields) => todo!(),
            Expression::Access(expression, identifier) => todo!(),
            Expression::Tagged(identifier, expression) => todo!(),
            Expression::Branched(branches) => todo!(),
            Expression::Function(args, body) => todo!(),
            Expression::Empty => todo!(),
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
            Identifier("c"),
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
            Identifier("v"),
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
                                Identifier("a"),
                            )),
                            Box::new(Expression::IntLiteral(2)),
                        )),
                        Box::new(Expression::IntLiteral(3)),
                    )),
                )),
                Box::new(Expression::Access(
                    Box::new(Expression::Identifier("s")),
                    Identifier("b"),
                )),
            )),
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn call_expressions_empty() {
        let source = "call()";

        let mut parser = Parser::new(source);

        let ast = parser.parse();
        let reference = Expression::Call(
            Container::Paren,
            Box::new(Expression::Identifier("call")),
            vec![Expression::Empty],
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn call_expressions() {
        let source = "call(1, 2, 3)";

        let mut parser = Parser::new(source);

        let ast = parser.parse();
        let reference = Expression::Call(
            Container::Paren,
            Box::new(Expression::Identifier("call")),
            vec![
                Expression::IntLiteral(1),
                Expression::IntLiteral(2),
                Expression::IntLiteral(3),
            ],
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn struct_definition() {
        let source = "a: struct {
            b: Int,
            c: Int,
        },

        x: a[b: 1, c: 2],
        y: a.b + a.c,
        ";

        let mut parser = Parser::new(source);

        let ast = parser.parse();

        let reference = Expression::List(
            Container::File,
            vec![
                Expression::Tagged(
                    Identifier("a"),
                    Box::new(Expression::Call(
                        Container::Brace,
                        Box::new(Expression::Identifier("struct")),
                        vec![
                            Expression::Tagged(
                                Identifier("b"),
                                Box::new(Expression::Identifier("Int")),
                            ),
                            Expression::Tagged(
                                Identifier("c"),
                                Box::new(Expression::Identifier("Int")),
                            ),
                            Expression::Empty,
                        ],
                    )),
                ),
                Expression::Tagged(
                    Identifier("x"),
                    Box::new(Expression::Call(
                        Container::Bracket,
                        Box::new(Expression::Identifier("a")),
                        vec![
                            Expression::Tagged(
                                Identifier("b"),
                                Box::new(Expression::IntLiteral(1)),
                            ),
                            Expression::Tagged(
                                Identifier("c"),
                                Box::new(Expression::IntLiteral(2)),
                            ),
                        ],
                    )),
                ),
                Expression::Tagged(
                    Identifier("y"),
                    Box::new(Expression::Binary(
                        Operator::Plus,
                        Box::new(Expression::Access(
                            Box::new(Expression::Identifier("a")),
                            Identifier("b"),
                        )),
                        Box::new(Expression::Access(
                            Box::new(Expression::Identifier("a")),
                            Identifier("c"),
                        )),
                    )),
                ),
                Expression::Empty,
            ],
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn prefix() {
        let source = "(3 + 2).to_float(x: a)";

        let mut parser = Parser::new(source);

        let ast = parser.parse();

        let reference = Expression::Call(
            Container::Paren,
            Box::new(Expression::Access(
                Box::new(Expression::Binary(
                    Operator::Plus,
                    Box::new(Expression::IntLiteral(3)),
                    Box::new(Expression::IntLiteral(2)),
                )),
                Identifier("to_float"),
            )),
            vec![Expression::Tagged(
                Identifier("x"),
                Box::new(Expression::Identifier("a")),
            )],
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn pipes() {
        let source = "
            \"we are the champions\"
            |> slice()[1, -1]
        ";

        let mut parser = Parser::new(source);

        let ast = parser.parse();

        let reference = Expression::Binary(
            Operator::Pipe,
            Box::new(Expression::StringLiteral("we are the champions")),
            Box::new(Expression::Call(
                Container::Bracket,
                Box::new(Expression::Call(
                    Container::Paren,
                    Box::new(Expression::Identifier("slice")),
                    vec![Expression::Empty],
                )),
                vec![
                    Expression::IntLiteral(1),
                    Expression::Unary(
                        Operator::Minus,
                        Box::new(Expression::IntLiteral(1)),
                    ),
                ],
            )),
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn multiple_functions() {
        let source = "
            first() + second(1) + third(x:3,)
        ";

        let mut parser = Parser::new(source);

        let ast = parser.parse();

        let reference = Expression::Binary(
            Operator::Plus,
            Box::new(Expression::Binary(
                Operator::Plus,
                Box::new(Expression::Call(
                    Container::Paren,
                    Box::new(Expression::Identifier("first")),
                    vec![Expression::Empty],
                )),
                Box::new(Expression::Call(
                    Container::Paren,
                    Box::new(Expression::Identifier("second")),
                    vec![Expression::IntLiteral(1)],
                )),
            )),
            Box::new(Expression::Call(
                Container::Paren,
                Box::new(Expression::Identifier("third")),
                vec![
                    Expression::Tagged(
                        Identifier("x"),
                        Box::new(Expression::IntLiteral(3)),
                    ),
                    Expression::Empty,
                ],
            )),
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn branched_expression() {
        let source = "|condition1, condition2| expression";

        let mut parser = Parser::new(source);

        let ast = parser.parse();

        let reference = Expression::Branched(vec![Branch {
            match_expression: Expression::List(
                Container::Guard,
                vec![
                    Expression::Identifier("condition1"),
                    Expression::Identifier("condition2"),
                ],
            ),
            guard_expression: None,
            body: Expression::Identifier("expression"),
        }]);

        assert_eq!(ast, reference);
    }

    #[test]
    fn complex_branched() {
        let source = "
            a: {
                |x: @a if a = 0| do_something()
                |_| do_nothing
            }
        ";

        let mut parser = Parser::new(source);

        let ast = parser.parse();

        let reference = Expression::Tagged(
            Identifier("a"),
            Box::new(Expression::Branched(vec![
                Branch {
                    match_expression: Expression::Tagged(
                        Identifier("x"),
                        Box::new(Expression::Binding("a")),
                    ),
                    guard_expression: Some(Expression::Binary(
                        Operator::Eq,
                        Box::new(Expression::Identifier("a")),
                        Box::new(Expression::IntLiteral(0)),
                    )),
                    body: Expression::Call(
                        Container::Paren,
                        Box::new(Expression::Identifier("do_something")),
                        vec![Expression::Empty],
                    ),
                },
                Branch {
                    match_expression: Expression::Special,
                    guard_expression: None,
                    body: Expression::Identifier("do_nothing"),
                },
            ])),
        );

        assert_eq!(ast, reference);
    }

    #[test]
    fn function_definition() {
        let source = "
            factorial: fn (i: int) -> int {
                3
            }
        ";

        let mut parser = Parser::new(source);

        let ast = parser.parse();

        let reference = Expression::Tagged(
            Identifier("factorial"),
            Box::new(Expression::Function(
                vec![Expression::Tagged(
                    Identifier("i"),
                    Box::new(Expression::Identifier("int")),
                )],
                Box::new(Expression::Call(
                    Container::Brace,
                    Box::new(Expression::Identifier("int")),
                    vec![Expression::IntLiteral(3)],
                )),
            )),
        );

        assert_eq!(ast, reference);
    }
}
