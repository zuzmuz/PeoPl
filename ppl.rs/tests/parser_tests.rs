use ppl::syntax::parser::{
    Branch, Container, ExprArena, ExprIdx, Expression, Identifier, Operator,
    Parser,
};

fn tree_eq<'a>(
    arena: &ExprArena<'a>,
    a: ExprIdx,
    other: &ExprArena<'a>,
    b: ExprIdx,
) -> bool {
    match (arena.get(a), other.get(b)) {
        (Expression::IntLiteral(x), Expression::IntLiteral(y)) => x == y,
        (Expression::FloatLiteral(x), Expression::FloatLiteral(y)) => {
            x.to_bits() == y.to_bits()
        }
        (Expression::ImaginaryLiteral(x), Expression::ImaginaryLiteral(y)) => {
            x.to_bits() == y.to_bits()
        }
        (Expression::StringLiteral(x), Expression::StringLiteral(y)) => x == y,
        (Expression::Identifier(x), Expression::Identifier(y)) => x == y,
        (Expression::Special, Expression::Special) => true,
        (Expression::PositionalStr(x), Expression::PositionalStr(y)) => x == y,
        (Expression::PositionalInt(x), Expression::PositionalInt(y)) => x == y,
        (Expression::Binding(x), Expression::Binding(y)) => x == y,
        (Expression::Unary(op1, e1), Expression::Unary(op2, e2)) => {
            let (e1, e2) = (*e1, *e2);
            op1 == op2 && tree_eq(arena, e1, other, e2)
        }
        (Expression::Binary(op1, l1, r1), Expression::Binary(op2, l2, r2)) => {
            let (l1, r1, l2, r2) = (*l1, *r1, *l2, *r2);
            op1 == op2
                && tree_eq(arena, l1, other, l2)
                && tree_eq(arena, r1, other, r2)
        }
        (Expression::List(c1, es1), Expression::List(c2, es2)) => {
            if c1 != c2 || es1.len() != es2.len() {
                return false;
            }
            let pairs: Vec<(ExprIdx, ExprIdx)> =
                es1.iter().copied().zip(es2.iter().copied()).collect();
            pairs.iter().all(|(a, b)| tree_eq(arena, *a, other, *b))
        }
        (Expression::Call(c1, f1, args1), Expression::Call(c2, f2, args2)) => {
            if c1 != c2 || args1.len() != args2.len() {
                return false;
            }
            let (f1, f2) = (*f1, *f2);
            let pairs: Vec<(ExprIdx, ExprIdx)> =
                args1.iter().copied().zip(args2.iter().copied()).collect();
            tree_eq(arena, f1, other, f2)
                && pairs.iter().all(|(a, b)| tree_eq(arena, *a, other, *b))
        }
        (
            Expression::AccessIdent(e1, id1),
            Expression::AccessIdent(e2, id2),
        ) => {
            let (e1, e2) = (*e1, *e2);
            id1 == id2 && tree_eq(arena, e1, other, e2)
        }
        (
            Expression::AccessPosition(e1, id1),
            Expression::AccessPosition(e2, id2),
        ) => {
            let (e1, e2) = (*e1, *e2);
            id1 == id2 && tree_eq(arena, e1, other, e2)
        }
        (Expression::Tagged(id1, e1), Expression::Tagged(id2, e2)) => {
            let (e1, e2) = (*e1, *e2);
            id1 == id2 && tree_eq(arena, e1, other, e2)
        }
        (Expression::Branched(bs1), Expression::Branched(bs2)) => {
            if bs1.len() != bs2.len() {
                return false;
            }
            let branch_pairs: Vec<(Branch, Branch)> =
                bs1.iter().cloned().zip(bs2.iter().cloned()).collect();
            branch_pairs.iter().all(|(b1, b2)| {
                tree_eq(arena, b1.match_expression, other, b2.match_expression)
                    && match (b1.guard_expression, b2.guard_expression) {
                        (None, None) => true,
                        (Some(g1), Some(g2)) => tree_eq(arena, g1, other, g2),
                        _ => false,
                    }
                    && tree_eq(arena, b1.body, other, b2.body)
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
            pairs.iter().all(|(a, b)| tree_eq(arena, *a, other, *b))
                && tree_eq(arena, body1, other, body2)
        }
        (Expression::Empty, Expression::Empty) => true,
        _ => false,
    }
}

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

    assert!(tree_eq(&arena, root, &r, list));
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

    assert!(tree_eq(&arena, root, &r, tagged));
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
    let exp = r.alloc(Expression::Binary(Operator::Exponent, access_a, int2));
    let int3 = r.alloc(Expression::IntLiteral(3));
    let times = r.alloc(Expression::Binary(Operator::Times, exp, int3));
    let uminus = r.alloc(Expression::Unary(Operator::Minus, times));
    let s2 = r.alloc(Expression::Identifier("s"));
    let access_b = r.alloc(Expression::AccessIdent(s2, Identifier("b")));
    let plus = r.alloc(Expression::Binary(Operator::Plus, uminus, access_b));
    let tagged = r.alloc(Expression::Tagged(Identifier("v"), plus));

    assert!(tree_eq(&arena, root, &r, tagged));
}

#[test]
fn call_expressions_empty() {
    let source = "call()";

    let parser = Parser::from_source(source);
    let (arena, root) = parser.parse();

    let mut r = ExprArena::new();
    let callee = r.alloc(Expression::Identifier("call"));
    let empty = r.alloc(Expression::Empty);
    let call = r.alloc(Expression::Call(Container::Paren, callee, vec![empty]));

    assert!(tree_eq(&arena, root, &r, call));
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
    let call =
        r.alloc(Expression::Call(Container::Paren, callee, vec![i1, i2, i3]));

    assert!(tree_eq(&arena, root, &r, call));
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
    let a_tagged = r.alloc(Expression::Tagged(Identifier("a"), struct_call));

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

    assert!(tree_eq(&arena, root, &r, list));
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
    let call = r.alloc(Expression::Call(Container::Paren, access, vec![x_a]));

    assert!(tree_eq(&arena, root, &r, call));
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
    let neg_one = r.alloc(Expression::Unary(Operator::Minus, neg_one_inner));
    let bracket_call = r.alloc(Expression::Call(
        Container::Bracket,
        slice_call,
        vec![one, neg_one],
    ));
    let pipe = r.alloc(Expression::Binary(Operator::Pipe, str_, bracket_call));

    assert!(tree_eq(&arena, root, &r, pipe));
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

    let plus1 =
        r.alloc(Expression::Binary(Operator::Plus, first_call, second_call));

    let third_id = r.alloc(Expression::Identifier("third"));
    let three = r.alloc(Expression::IntLiteral(3));
    let x3 = r.alloc(Expression::Tagged(Identifier("x"), three));
    let empty2 = r.alloc(Expression::Empty);
    let third_call = r.alloc(Expression::Call(
        Container::Paren,
        third_id,
        vec![x3, empty2],
    ));

    let plus2 = r.alloc(Expression::Binary(Operator::Plus, plus1, third_call));

    assert!(tree_eq(&arena, root, &r, plus2));
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

    assert!(tree_eq(&arena, root, &r, branched));
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

    assert!(tree_eq(&arena, root, &r, tagged));
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
    let body = r.alloc(Expression::Call(Container::Brace, int_id, vec![three]));
    let func = r.alloc(Expression::Function(vec![param], body));
    let tagged = r.alloc(Expression::Tagged(Identifier("factorial"), func));

    assert!(tree_eq(&arena, root, &r, tagged));
}
