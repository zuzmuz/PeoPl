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

    Function(Vec<ExprIdx>, ExprIdx),

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
                            self.continue_parsing(3, expression, container);
                        // 3 because we need to know when to stop parsing,
                        self.alloc(Expression::Function(
                            vec![function_params],
                            continued_expression,
                        ))
                    } else {
                        todo!("need arrow for function")
                    }
                }
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

#[cfg(test)]
impl<'a> ExprArena<'a> {
    /// Structural equality check between two trees, potentially in different arenas.
    fn tree_eq(&self, a: ExprIdx, other: &ExprArena<'a>, b: ExprIdx) -> bool {
        match (self.get(a), other.get(b)) {
            (Expression::IntLiteral(x), Expression::IntLiteral(y)) => x == y,
            (Expression::FloatLiteral(x), Expression::FloatLiteral(y)) => {
                x.to_bits() == y.to_bits()
            }
            (
                Expression::ImaginaryLiteral(x),
                Expression::ImaginaryLiteral(y),
            ) => x.to_bits() == y.to_bits(),
            (Expression::StringLiteral(x), Expression::StringLiteral(y)) => {
                x == y
            }
            (Expression::Identifier(x), Expression::Identifier(y)) => x == y,
            (Expression::Special, Expression::Special) => true,
            (Expression::PositionalStr(x), Expression::PositionalStr(y)) => x == y,
            (Expression::PositionalInt(x), Expression::PositionalInt(y)) => x == y,
            (Expression::Binding(x), Expression::Binding(y)) => x == y,
            (Expression::Unary(op1, e1), Expression::Unary(op2, e2)) => {
                let (e1, e2) = (*e1, *e2);
                op1 == op2 && self.tree_eq(e1, other, e2)
            }
            (
                Expression::Binary(op1, l1, r1),
                Expression::Binary(op2, l2, r2),
            ) => {
                let (l1, r1, l2, r2) = (*l1, *r1, *l2, *r2);
                op1 == op2
                    && self.tree_eq(l1, other, l2)
                    && self.tree_eq(r1, other, r2)
            }
            (Expression::List(c1, es1), Expression::List(c2, es2)) => {
                if c1 != c2 || es1.len() != es2.len() {
                    return false;
                }
                let pairs: Vec<(ExprIdx, ExprIdx)> =
                    es1.iter().copied().zip(es2.iter().copied()).collect();
                pairs.iter().all(|(a, b)| self.tree_eq(*a, other, *b))
            }
            (
                Expression::Call(c1, f1, args1),
                Expression::Call(c2, f2, args2),
            ) => {
                if c1 != c2 || args1.len() != args2.len() {
                    return false;
                }
                let (f1, f2) = (*f1, *f2);
                let pairs: Vec<(ExprIdx, ExprIdx)> =
                    args1.iter().copied().zip(args2.iter().copied()).collect();
                self.tree_eq(f1, other, f2)
                    && pairs.iter().all(|(a, b)| self.tree_eq(*a, other, *b))
            }
            (Expression::AccessIdent(e1, id1), Expression::AccessIdent(e2, id2)) => {
                let (e1, e2) = (*e1, *e2);
                id1 == id2 && self.tree_eq(e1, other, e2)
            }
            (Expression::AccessPosition(e1, id1), Expression::AccessPosition(e2, id2)) => {
                let (e1, e2) = (*e1, *e2);
                id1 == id2 && self.tree_eq(e1, other, e2)
            }
            (Expression::Tagged(id1, e1), Expression::Tagged(id2, e2)) => {
                let (e1, e2) = (*e1, *e2);
                id1 == id2 && self.tree_eq(e1, other, e2)
            }
            (Expression::Branched(bs1), Expression::Branched(bs2)) => {
                if bs1.len() != bs2.len() {
                    return false;
                }
                let branch_pairs: Vec<(Branch, Branch)> =
                    bs1.iter().cloned().zip(bs2.iter().cloned()).collect();
                branch_pairs.iter().all(|(b1, b2)| {
                    self.tree_eq(
                        b1.match_expression,
                        other,
                        b2.match_expression,
                    ) && match (b1.guard_expression, b2.guard_expression) {
                        (None, None) => true,
                        (Some(g1), Some(g2)) => self.tree_eq(g1, other, g2),
                        _ => false,
                    } && self.tree_eq(b1.body, other, b2.body)
                })
            }
            (
                Expression::Function(params1, body1),
                Expression::Function(params2, body2),
            ) => {
                if params1.len() != params2.len() {
                    return false;
                }
                let (body1, body2) = (*body1, *body2);
                let pairs: Vec<(ExprIdx, ExprIdx)> = params1
                    .iter()
                    .copied()
                    .zip(params2.iter().copied())
                    .collect();
                pairs.iter().all(|(a, b)| self.tree_eq(*a, other, *b))
                    && self.tree_eq(body1, other, body2)
            }
            (Expression::Empty, Expression::Empty) => true,
            _ => false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn numbers() {
        let source = "1, 0x12, 3.4";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let i1 = r.alloc(Expression::IntLiteral(1));
        let i2 = r.alloc(Expression::IntLiteral(18));
        let f = r.alloc(Expression::FloatLiteral(3.4));
        let list = r.alloc(Expression::List(Container::File, vec![i1, i2, f]));

        assert!(arena.tree_eq(root, &r, list));
    }

    #[test]
    fn basic() {
        let source = "
            c: - 1 * 4 > 3 - 2 and value = \"string\"
        ";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let int1 = r.alloc(Expression::IntLiteral(1));
        let int4 = r.alloc(Expression::IntLiteral(4));
        let times = r.alloc(Expression::Binary(Operator::Times, int1, int4));
        let uminus = r.alloc(Expression::Unary(Operator::Minus, times));
        let int3 = r.alloc(Expression::IntLiteral(3));
        let int2 = r.alloc(Expression::IntLiteral(2));
        let sub = r.alloc(Expression::Binary(Operator::Minus, int3, int2));
        let gt = r.alloc(Expression::Binary(Operator::Gt, uminus, sub));
        let val = r.alloc(Expression::Identifier("value"));
        let str_ = r.alloc(Expression::StringLiteral("string"));
        let eq = r.alloc(Expression::Binary(Operator::Eq, val, str_));
        let and = r.alloc(Expression::Binary(Operator::And, gt, eq));
        let tagged = r.alloc(Expression::Tagged(Identifier("c"), and));

        assert!(arena.tree_eq(root, &r, tagged));
    }

    #[test]
    fn member_access() {
        let source = "
            v: - s.a ^ 2 * 3 + s.b
        ";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let s1 = r.alloc(Expression::Identifier("s"));
        let access_a = r.alloc(Expression::AccessIdent(s1, Identifier("a")));
        let int2 = r.alloc(Expression::IntLiteral(2));
        let exp =
            r.alloc(Expression::Binary(Operator::Exponent, access_a, int2));
        let int3 = r.alloc(Expression::IntLiteral(3));
        let times = r.alloc(Expression::Binary(Operator::Times, exp, int3));
        let uminus = r.alloc(Expression::Unary(Operator::Minus, times));
        let s2 = r.alloc(Expression::Identifier("s"));
        let access_b = r.alloc(Expression::AccessIdent(s2, Identifier("b")));
        let plus =
            r.alloc(Expression::Binary(Operator::Plus, uminus, access_b));
        let tagged = r.alloc(Expression::Tagged(Identifier("v"), plus));

        assert!(arena.tree_eq(root, &r, tagged));
    }

    #[test]
    fn call_expressions_empty() {
        let source = "call()";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let callee = r.alloc(Expression::Identifier("call"));
        let empty = r.alloc(Expression::Empty);
        let call =
            r.alloc(Expression::Call(Container::Paren, callee, vec![empty]));

        assert!(arena.tree_eq(root, &r, call));
    }

    #[test]
    fn call_expressions() {
        let source = "call(1, 2, 3)";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let callee = r.alloc(Expression::Identifier("call"));
        let i1 = r.alloc(Expression::IntLiteral(1));
        let i2 = r.alloc(Expression::IntLiteral(2));
        let i3 = r.alloc(Expression::IntLiteral(3));
        let call = r.alloc(Expression::Call(
            Container::Paren,
            callee,
            vec![i1, i2, i3],
        ));

        assert!(arena.tree_eq(root, &r, call));
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

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();

        // a: struct { b: Int, c: Int, }
        let struct_id = r.alloc(Expression::Identifier("struct"));
        let int_b = r.alloc(Expression::Identifier("Int"));
        let int_c = r.alloc(Expression::Identifier("Int"));
        let tagged_b = r.alloc(Expression::Tagged(Identifier("b"), int_b));
        let tagged_c = r.alloc(Expression::Tagged(Identifier("c"), int_c));
        let empty1 = r.alloc(Expression::Empty);
        let struct_call = r.alloc(Expression::Call(
            Container::Brace,
            struct_id,
            vec![tagged_b, tagged_c, empty1],
        ));
        let a_tagged =
            r.alloc(Expression::Tagged(Identifier("a"), struct_call));

        // x: a[b: 1, c: 2]
        let a_id = r.alloc(Expression::Identifier("a"));
        let one = r.alloc(Expression::IntLiteral(1));
        let two = r.alloc(Expression::IntLiteral(2));
        let b1 = r.alloc(Expression::Tagged(Identifier("b"), one));
        let c2 = r.alloc(Expression::Tagged(Identifier("c"), two));
        let a_bracket =
            r.alloc(Expression::Call(Container::Bracket, a_id, vec![b1, c2]));
        let x_tagged = r.alloc(Expression::Tagged(Identifier("x"), a_bracket));

        // y: a.b + a.c
        let a1 = r.alloc(Expression::Identifier("a"));
        let access_ab = r.alloc(Expression::AccessIdent(a1, Identifier("b")));
        let a2 = r.alloc(Expression::Identifier("a"));
        let access_ac = r.alloc(Expression::AccessIdent(a2, Identifier("c")));
        let plus =
            r.alloc(Expression::Binary(Operator::Plus, access_ab, access_ac));
        let y_tagged = r.alloc(Expression::Tagged(Identifier("y"), plus));

        let empty2 = r.alloc(Expression::Empty);
        let list = r.alloc(Expression::List(
            Container::File,
            vec![a_tagged, x_tagged, y_tagged, empty2],
        ));

        assert!(arena.tree_eq(root, &r, list));
    }

    #[test]
    fn prefix() {
        let source = "(3 + 2).to_float(x: a)";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let three = r.alloc(Expression::IntLiteral(3));
        let two = r.alloc(Expression::IntLiteral(2));
        let plus = r.alloc(Expression::Binary(Operator::Plus, three, two));
        let access = r.alloc(Expression::AccessIdent(plus, Identifier("to_float")));
        let a_id = r.alloc(Expression::Identifier("a"));
        let x_a = r.alloc(Expression::Tagged(Identifier("x"), a_id));
        let call =
            r.alloc(Expression::Call(Container::Paren, access, vec![x_a]));

        assert!(arena.tree_eq(root, &r, call));
    }

    #[test]
    fn pipes() {
        let source = "
            \"we are the champions\"
            |> slice()[1, -1]
        ";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let str_ = r.alloc(Expression::StringLiteral("we are the champions"));
        let slice_id = r.alloc(Expression::Identifier("slice"));
        let empty = r.alloc(Expression::Empty);
        let slice_call =
            r.alloc(Expression::Call(Container::Paren, slice_id, vec![empty]));
        let one = r.alloc(Expression::IntLiteral(1));
        let neg_one_inner = r.alloc(Expression::IntLiteral(1));
        let neg_one =
            r.alloc(Expression::Unary(Operator::Minus, neg_one_inner));
        let bracket_call = r.alloc(Expression::Call(
            Container::Bracket,
            slice_call,
            vec![one, neg_one],
        ));
        let pipe =
            r.alloc(Expression::Binary(Operator::Pipe, str_, bracket_call));

        assert!(arena.tree_eq(root, &r, pipe));
    }

    #[test]
    fn multiple_functions() {
        let source = "
            first() + second(1) + third(x:3,)
        ";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();

        let first_id = r.alloc(Expression::Identifier("first"));
        let empty1 = r.alloc(Expression::Empty);
        let first_call =
            r.alloc(Expression::Call(Container::Paren, first_id, vec![empty1]));

        let second_id = r.alloc(Expression::Identifier("second"));
        let one = r.alloc(Expression::IntLiteral(1));
        let second_call =
            r.alloc(Expression::Call(Container::Paren, second_id, vec![one]));

        let plus1 = r.alloc(Expression::Binary(
            Operator::Plus,
            first_call,
            second_call,
        ));

        let third_id = r.alloc(Expression::Identifier("third"));
        let three = r.alloc(Expression::IntLiteral(3));
        let x3 = r.alloc(Expression::Tagged(Identifier("x"), three));
        let empty2 = r.alloc(Expression::Empty);
        let third_call = r.alloc(Expression::Call(
            Container::Paren,
            third_id,
            vec![x3, empty2],
        ));

        let plus2 =
            r.alloc(Expression::Binary(Operator::Plus, plus1, third_call));

        assert!(arena.tree_eq(root, &r, plus2));
    }

    #[test]
    fn branched_expression() {
        let source = "|condition1, condition2| expression";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let cond1 = r.alloc(Expression::Identifier("condition1"));
        let cond2 = r.alloc(Expression::Identifier("condition2"));
        let match_expr =
            r.alloc(Expression::List(Container::Guard, vec![cond1, cond2]));
        let body = r.alloc(Expression::Identifier("expression"));
        let branched = r.alloc(Expression::Branched(vec![Branch {
            match_expression: match_expr,
            guard_expression: None,
            body,
        }]));

        assert!(arena.tree_eq(root, &r, branched));
    }

    #[test]
    fn complex_branched() {
        let source = "
            a: {
                |x: @a if a = 0| do_something()
                |_| do_nothing
            }
        ";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();

        // Branch 1: x: @a if a = 0 | do_something()
        let binding_a = r.alloc(Expression::Binding("a"));
        let match1 = r.alloc(Expression::Tagged(Identifier("x"), binding_a));
        let a_id = r.alloc(Expression::Identifier("a"));
        let zero = r.alloc(Expression::IntLiteral(0));
        let guard1 = r.alloc(Expression::Binary(Operator::Eq, a_id, zero));
        let do_something = r.alloc(Expression::Identifier("do_something"));
        let empty = r.alloc(Expression::Empty);
        let body1 = r.alloc(Expression::Call(
            Container::Paren,
            do_something,
            vec![empty],
        ));

        // Branch 2: _ | do_nothing
        let special = r.alloc(Expression::Special);
        let body2 = r.alloc(Expression::Identifier("do_nothing"));

        let branched = r.alloc(Expression::Branched(vec![
            Branch {
                match_expression: match1,
                guard_expression: Some(guard1),
                body: body1,
            },
            Branch {
                match_expression: special,
                guard_expression: None,
                body: body2,
            },
        ]));
        let tagged = r.alloc(Expression::Tagged(Identifier("a"), branched));

        assert!(arena.tree_eq(root, &r, tagged));
    }

    #[test]
    fn function_definition() {
        let source = "
            factorial: fn (i: int) -> int {
                3
            }
        ";

        let parser = Parser::from_source(source);
        let (arena, root) = parser.parse();

        let mut r = ExprArena::new();
        let i_id = r.alloc(Expression::Identifier("int"));
        let param = r.alloc(Expression::Tagged(Identifier("i"), i_id));
        let int_id = r.alloc(Expression::Identifier("int"));
        let three = r.alloc(Expression::IntLiteral(3));
        let body =
            r.alloc(Expression::Call(Container::Brace, int_id, vec![three]));
        let func = r.alloc(Expression::Function(vec![param], body));
        let tagged = r.alloc(Expression::Tagged(Identifier("factorial"), func));

        assert!(arena.tree_eq(root, &r, tagged));
    }
}
