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

impl ToString for Operator {
    fn to_string(&self) -> String {
        match self {
            Operator::Exponent => "^".to_string(),
            Operator::Times => "*".to_string(),
            Operator::By => "/".to_string(),
            Operator::Mod => "%".to_string(),
            Operator::Plus => "+".to_string(),
            Operator::Minus => "-".to_string(),
            Operator::Lshift => "<<".to_string(),
            Operator::Rshift => ">>".to_string(),
            Operator::Band => ".&".to_string(),
            Operator::Bor => ".|".to_string(),
            Operator::Bxor => ".^".to_string(),
            Operator::Eq => "=".to_string(),
            Operator::Ge => ">=".to_string(),
            Operator::Gt => ">".to_string(),
            Operator::Le => "<=".to_string(),
            Operator::Lt => "<".to_string(),
            Operator::And => "and".to_string(),
            Operator::Or => "or".to_string(),
            Operator::Pipe => "|>".to_string(),
            Operator::Not => "not".to_string(),
            Operator::Bnot => "~".to_string(),
        }
    }
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

impl ToString for Container {
    fn to_string(&self) -> String {
        match self {
            Container::Paren => "()".to_string(),
            Container::Bracket => "[]".to_string(),
            Container::Brace => "{}".to_string(),
            Container::Guard => "||".to_string(),
            Container::BranchBody => "|}".to_string(),
            Container::File => "FILE".to_string(),
        }
    }
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
            | Token::Identifier(_)
            | Token::PositionalStr(_)
            | Token::PositionalInt(_)
            | Token::Arrow
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

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub struct ExprIdx(pub usize);

pub struct ExprArena<'a> {
    expressions: Vec<Expression<'a>>,
}

impl<'a> ExprArena<'a> {
    pub fn new() -> Self {
        ExprArena {
            expressions: Vec::new(),
        }
    }

    pub fn with_capacity(capacity: usize) -> Self {
        ExprArena {
            expressions: Vec::with_capacity(capacity),
        }
    }

    pub fn alloc(&mut self, expr: Expression<'a>) -> ExprIdx {
        let idx = self.expressions.len();
        self.expressions.push(expr);
        ExprIdx(idx)
    }

    pub fn get(&self, idx: ExprIdx) -> &Expression<'a> {
        &self.expressions[idx.0]
    }

    pub fn get_mut(&mut self, idx: ExprIdx) -> &mut Expression<'a> {
        &mut self.expressions[idx.0]
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Identifier<'a>(pub &'a str);

#[derive(Clone, Debug, PartialEq)]
pub struct Branch {
    pub match_expression: ExprIdx,
    pub guard_expression: Option<ExprIdx>,
    pub body: ExprIdx,
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
    PositionalStr(&'a str),
    PositionalInt(u64),
    Binding(&'a str),

    // primary
    Unary(Operator, ExprIdx),
    Binary(Operator, ExprIdx, ExprIdx),

    List(Container, Vec<ExprIdx>),
    Call(Container, ExprIdx, Vec<ExprIdx>),
    AccessIdent(ExprIdx, Identifier<'a>),
    AccessPosition(ExprIdx, u64),

    Tagged(Identifier<'a>, ExprIdx),

    Branched(Vec<Branch>),

    Function(Container, Vec<ExprIdx>, ExprIdx),

    Empty,
    // Invalid,
}

pub struct Parser<'a> {
    tokens: Vec<Token<'a>>,
    cursor: usize,
    arena: ExprArena<'a>,
}

impl<'a> Parser<'a> {
    pub fn from_source(source: &'a str) -> Self {
        let tokens = tokenizer::lex_source(source);
        let tokens_len = tokens.len();
        Parser {
            tokens,
            cursor: 0,
            arena: ExprArena::with_capacity(tokens_len / 4),
        }
    }

    pub fn from_tokens(tokens: Vec<Token<'a>>) -> Self {
        let tokens_len = tokens.len();
        Parser {
            tokens,
            cursor: 0,
            arena: ExprArena::with_capacity(tokens_len / 4),
        }
    }

    pub fn parse(mut self) -> (ExprArena<'a>, ExprIdx) {
        let root = self.parse_complex_expression(Container::File);
        (self.arena, root)
    }

    fn alloc(&mut self, expr: Expression<'a>) -> ExprIdx {
        self.arena.alloc(expr)
    }

    fn skip_to_next_valid_token(&mut self) {
        while self.tokens[self.cursor].precedence() == -3 {
            self.cursor += 1;
        }
    }

    fn advance(&mut self) {
        log::debug!(
            "advancing from {:?}: {:?}",
            self.cursor,
            self.tokens[self.cursor]
        );

        self.cursor += 1;
        self.skip_to_next_valid_token();

        log::debug!(
            "advancing to {:?}: {:?}",
            self.cursor,
            self.tokens[self.cursor]
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

    /// A complex expression is one that is inside a container
    ///
    /// : Branched
    /// | PrimaryExpression
    fn parse_complex_expression(&mut self, container: Container) -> ExprIdx {
        self.skip_to_next_valid_token();
        match &self.tokens[self.cursor] {
            // When parsing complex expression if we encounter a `Token::Bar`
            // we expect a branching expression
            Token::Bar => {
                let mut branches: Vec<Branch> = Vec::new();

                loop {
                    self.advance();
                    let expression =
                        self.parse_primary_expression(Container::Guard);
                    let continued_expression =
                        self.continue_parsing(0, expression, Container::Guard);
                    self.advance();

                    let (match_expression, guard_expression): (
                        ExprIdx,
                        Option<ExprIdx>,
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
                self.alloc(Expression::Branched(branches))
            }
            // otherwise it's just a regular expression
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
        last_expression: ExprIdx,
        container: Container,
    ) -> ExprIdx {
        let mut last_expression = last_expression;
        loop {
            log::debug!("Last {:#?}", self.arena.get(last_expression));
            let operator_token = self.peek_next_token();
            log::debug!("Current token {:?}", operator_token);

            let current_precedence = operator_token.precedence();

            if current_precedence == -1 {
                // expecting operator token got something else
                todo!("handle syntax error properly");
            }

            if let Some(container_closing) = operator_token.closing() {
                log::debug!(
                    "closing the token {:?}, from {:?} container {:?}",
                    container_closing,
                    operator_token,
                    container,
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

            log::debug!("precc {current_precedence} {last_precedence}");
            if current_precedence < last_precedence {
                // past expression chain had higher precedence
                // stop parsing and return expression
                return last_expression;
            }

            if let Some(opening_container) = operator_token.opening() {
                // Found opening, it is a call expression
                self.advance();
                self.advance();
                let fields_expression =
                    self.parse_complex_expression(opening_container);

                let fields = match self.arena.get(fields_expression) {
                    Expression::List(_, vec) => vec.clone(),
                    _ => vec![fields_expression],
                };

                self.advance();

                last_expression = self.alloc(Expression::Call(
                    opening_container,
                    last_expression,
                    fields,
                ));
                continue;
            }

            // if not call expression

            self.advance();
            self.advance();

            let next_expression = self.parse_primary_expression(container);

            // let next_precedence = self.peek_next_token().precedence();
            let next_precedence = self.tokens[self.cursor + 1].precedence();

            let next_expression = if current_precedence < next_precedence {
                self.continue_parsing(
                    current_precedence + 1,
                    next_expression,
                    container,
                )
            } else {
                next_expression
            };

            if operator_token == Token::Comma {
                if matches!(
                    self.arena.get(last_expression),
                    Expression::List(_, _)
                ) {
                    if let Expression::List(_, vec) =
                        self.arena.get_mut(last_expression)
                    {
                        vec.push(next_expression);
                    }
                } else {
                    last_expression = self.alloc(Expression::List(
                        container,
                        vec![last_expression, next_expression],
                    ));
                }
            } else if operator_token == Token::Colon {
                let ident_str = match self.arena.get(last_expression) {
                    Expression::Identifier(ident) => *ident,
                    _ => todo!(
                        "tagged expression requires lhs to be an identifier"
                    ),
                };
                last_expression = self.alloc(Expression::Tagged(
                    Identifier(ident_str),
                    next_expression,
                ));
            } else if let Some(operator) = operator_token.operator() {
                if operator.is_binary() {
                    last_expression = self.alloc(Expression::Binary(
                        operator,
                        last_expression,
                        next_expression,
                    ));
                } else {
                    todo!("syntax error illegal unary operator");
                }
            } else if operator_token == Token::Backslash {
                todo!("qualified identifiers");
            } else if operator_token == Token::Dot {
                last_expression = match self.arena.get(next_expression) {
                    Expression::Identifier(ident) => {
                        self.alloc(Expression::AccessIdent(
                            last_expression,
                            Identifier(*ident),
                        ))
                    }
                    Expression::IntLiteral(position) => self.alloc(
                        Expression::AccessPosition(last_expression, *position),
                    ),
                    _ => todo!(
                        "access expression requires rhs to be an identifier"
                    ),
                };
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
    fn parse_primary_expression(&mut self, container: Container) -> ExprIdx {
        log::debug!("Parsing Literal {:?}", self.tokens[self.cursor]);
        match self.tokens[self.cursor] {
            Token::DecLiteral(value)
            | Token::HexLiteral(value)
            | Token::OctLiteral(value)
            | Token::BinLiteral(value) => {
                self.alloc(Expression::IntLiteral(value))
            }
            Token::FloatLiteral(value) => {
                self.alloc(Expression::FloatLiteral(value))
            }
            Token::ImaginaryLiteral(value) => {
                self.alloc(Expression::ImaginaryLiteral(value))
            }
            Token::StringLiteral(value) => {
                self.alloc(Expression::StringLiteral(value))
            }
            Token::PositionalStr(value) => {
                self.alloc(Expression::PositionalStr(value))
            }
            Token::PositionalInt(value) => {
                self.alloc(Expression::PositionalInt(value))
            }
            Token::Binding(value) => self.alloc(Expression::Binding(value)),
            Token::Special => self.alloc(Expression::Special),
            Token::Identifier(value) => {
                self.alloc(Expression::Identifier(value))
            }
            Token::KwordIf => {
                todo!("handle empty match expression");
            }
            Token::Bar => {
                todo!("handle error no bars are allowed");
            }
            Token::KwordFn => {
                self.advance();
                let mut compile_groups: Vec<ExprIdx> = Vec::new();
                let mut runtime_groups: Vec<ExprIdx> = Vec::new();
                while self.tokens[self.cursor] == Token::Lbracket {
                    compile_groups
                        .push(self.parse_primary_expression(container));
                    self.advance();
                }
                if self.tokens[self.cursor] != Token::Lparen {
                    todo!("fn should have at least one runtime param group")
                }
                while self.tokens[self.cursor] == Token::Lparen {
                    runtime_groups
                        .push(self.parse_primary_expression(container));
                    self.advance();
                }
                if self.tokens[self.cursor] != Token::Arrow {
                    todo!("need arrow for function")
                }
                self.advance();
                let expression = self.parse_primary_expression(container);
                // 3 because we need to know when to stop parsing
                let mut body =
                    self.continue_parsing(3, expression, container);
                for params in runtime_groups.into_iter().rev() {
                    body = self.alloc(Expression::Function(
                        Container::Paren,
                        vec![params],
                        body,
                    ));
                }
                for params in compile_groups.into_iter().rev() {
                    body = self.alloc(Expression::Function(
                        Container::Bracket,
                        vec![params],
                        body,
                    ));
                }
                body
            }
            token => {
                if let Some(container_opening) = token.opening() {
                    self.advance();
                    let inside_expression =
                        self.parse_complex_expression(container_opening);
                    self.advance();
                    inside_expression
                } else if let Some(container_closing) = token.closing() {
                    if container_closing == container {
                        self.cursor -= 1;
                        self.alloc(Expression::Empty)
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
                    self.alloc(Expression::Unary(
                        operator,
                        continued_expression,
                    ))
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
