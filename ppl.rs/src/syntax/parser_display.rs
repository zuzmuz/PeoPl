use crate::syntax::parser::{ExprArena, ExprIdx, Expression};
use colored::{self, ColoredString, Colorize};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Connector {
    Last,
    NotLast,
}

impl Connector {
    // TODO: use proper str instead of String
    fn display(&self) -> ColoredString {
        match self {
            Self::Last => "└─ ".bright_black(),
            Self::NotLast => "├─ ".bright_black(),
        }
    }

    fn child_prefix(&self) -> ColoredString {
        match self {
            Self::Last => "   ".bright_black(),
            Self::NotLast => "│  ".bright_black(),
        }
    }
}

pub fn display_ast<'a>(
    arena: &ExprArena<'a>,
    idx: ExprIdx,
    prefix: String,
    connector: Connector,
    extra: String,
    descriptions: &mut Vec<String>,
) {
    let child_prefix = format!("{}{}", prefix, connector.child_prefix());
    match arena.get(idx) {
        Expression::IntLiteral(value) => {
            descriptions.push(format!(
                "{}{}{}{}: {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Int".yellow(),
                value.to_string().green()
            ));
        }
        Expression::FloatLiteral(value) => {
            descriptions.push(format!(
                "{}{}{}{}: {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Float".yellow(),
                value.to_string().green()
            ));
        }
        Expression::ImaginaryLiteral(value) => {
            descriptions.push(format!(
                "{}{}{}{}: {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Imaginary".yellow(),
                format!("{value}i").green()
            ));
        }
        Expression::StringLiteral(value) => {
            descriptions.push(format!(
                "{}{}{}{}: {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "String".yellow(),
                value.green()
            ));
        }
        Expression::Identifier(value) => {
            descriptions.push(format!(
                "{}{}{}{}: {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Identifier".yellow(),
                value.green()
            ));
        }
        Expression::Special => {
            descriptions.push(format!(
                "{}{}{}{}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Special".yellow(),
            ));
        }
        Expression::PositionalStr(_) => todo!(),
        Expression::PositionalInt(_) => todo!(),
        Expression::Binding(_) => todo!(),
        Expression::Unary(operator, expr) => {
            let expr = *expr;
            descriptions.push(format!(
                "{}{}{} {}",
                prefix,
                connector.display(),
                extra.cyan(),
                operator.to_string().bright_red()
            ));

            display_ast(
                arena,
                expr,
                child_prefix,
                Connector::Last,
                "expr: ".to_string(),
                descriptions,
            );
        }
        Expression::Binary(operator, lhs, rhs) => {
            let (lhs, rhs) = (*lhs, *rhs);
            descriptions.push(format!(
                "{}{}{}{}",
                prefix,
                connector.display(),
                extra.cyan(),
                operator.to_string().bright_red()
            ));

            display_ast(
                arena,
                lhs,
                child_prefix.clone(),
                Connector::NotLast,
                "lhs: ".to_string(),
                descriptions,
            );
            display_ast(
                arena,
                rhs,
                child_prefix,
                Connector::Last,
                "rhs: ".to_string(),
                descriptions,
            );
        }
        Expression::List(container, expressions) => {
            let (container, expressions) = (*container, expressions.clone());
            descriptions.push(format!(
                "{}{}{}{} {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "List -".yellow(),
                container.to_string().blue()
            ));
            for (index, expr) in expressions.iter().enumerate() {
                let is_last_arg = index == expressions.len() - 1;
                display_ast(
                    arena,
                    *expr,
                    child_prefix.clone(),
                    if is_last_arg {
                        Connector::Last
                    } else {
                        Connector::NotLast
                    },
                    format!("#{} ", index),
                    descriptions,
                );
            }
        }
        Expression::Call(container, prefix_expr, fields) => {
            let (container, prefix_expr, fields) =
                (*container, *prefix_expr, fields.clone());
            descriptions.push(format!(
                "{}{}{}{} {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Call -".red(),
                container.to_string().blue()
            ));

            display_ast(
                arena,
                prefix_expr,
                child_prefix.clone(),
                Connector::NotLast,
                "prefix: ".to_string(),
                descriptions,
            );

            for (index, expr) in fields.iter().enumerate() {
                let is_last_arg = index == fields.len() - 1;
                display_ast(
                    arena,
                    *expr,
                    child_prefix.clone(),
                    if is_last_arg {
                        Connector::Last
                    } else {
                        Connector::NotLast
                    },
                    format!("#{} ", index),
                    descriptions,
                );
            }
        }
        Expression::AccessIdent(expr, identifier) => {
            let (expr, identifier_str) = (*expr, identifier.0.to_string());
            descriptions.push(format!(
                "{}{}{}{} {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Access -".red(),
                identifier_str.blue()
            ));

            display_ast(
                arena,
                expr,
                child_prefix,
                Connector::Last,
                "prefix: ".to_string(),
                descriptions,
            );
        }
        Expression::AccessPosition(expr, position) => {
            let (expr, position) = (*expr, position);
            descriptions.push(format!(
                "{}{}{}{} {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Access -".red(),
                format!("{}", position)
            ));

            display_ast(
                arena,
                expr,
                child_prefix,
                Connector::Last,
                "prefix: ".to_string(),
                descriptions,
            );
        }
        Expression::Tagged(identifier, expr) => {
            let (identifier_str, expr) = (identifier.0.to_string(), *expr);
            descriptions.push(format!(
                "{}{}{}{} {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Tagged -".red(),
                identifier_str.blue()
            ));

            display_ast(
                arena,
                expr,
                child_prefix,
                Connector::Last,
                "expr: ".to_string(),
                descriptions,
            );
        }
        Expression::Branched(branches) => {
            let branches = branches.clone();
            descriptions.push(format!(
                "{}{}{}{}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Branched".red(),
            ));

            for (index, branch) in branches.iter().enumerate() {
                let is_last_branch = index == branches.len() - 1;
                let branch_connector = if is_last_branch {
                    Connector::Last
                } else {
                    Connector::NotLast
                };
                descriptions.push(format!(
                    "{}{}{}{}",
                    child_prefix.clone(),
                    branch_connector.display(),
                    format!("#{}: ", index).cyan(),
                    "Branch".red()
                ));

                let branch_child_prefix = format!(
                    "{}{}",
                    child_prefix,
                    branch_connector.child_prefix()
                );

                display_ast(
                    arena,
                    branch.match_expression,
                    branch_child_prefix.clone(),
                    Connector::NotLast,
                    "match: ".to_string(),
                    descriptions,
                );

                if let Some(guard_expression) = branch.guard_expression {
                    display_ast(
                        arena,
                        guard_expression,
                        branch_child_prefix.clone(),
                        Connector::NotLast,
                        "guard: ".to_string(),
                        descriptions,
                    );
                }

                descriptions.push(format!(
                    "{}{}{}{}",
                    branch_child_prefix,
                    Connector::Last.display(),
                    "".to_string(),
                    "Body".red(),
                ));

                let body_prefix = format!(
                    "{}{}",
                    branch_child_prefix,
                    Connector::Last.child_prefix()
                );

                display_ast(
                    arena,
                    branch.body,
                    body_prefix,
                    Connector::Last,
                    "".to_string(),
                    descriptions,
                );
            }
        }
        Expression::Function(params, body) => {
            let (params, body) = (params.clone(), *body);
            descriptions.push(format!(
                "{}{}{}{}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Function".red(),
            ));

            descriptions.push(format!(
                "{}{}{}",
                child_prefix.clone(),
                Connector::NotLast.display(),
                "Arguments".bright_yellow()
            ));

            let arguments_prefix = format!(
                "{}{}",
                child_prefix,
                Connector::NotLast.child_prefix()
            );

            for (index, param) in params.iter().enumerate() {
                let is_last_arg = index == params.len() - 1;
                display_ast(
                    arena,
                    *param,
                    arguments_prefix.clone(),
                    if is_last_arg {
                        Connector::Last
                    } else {
                        Connector::NotLast
                    },
                    format!("#{} ", index),
                    descriptions,
                );
            }

            descriptions.push(format!(
                "{}{}{}{}",
                child_prefix,
                Connector::Last.display(),
                "".to_string(),
                "Output".bright_yellow()
            ));

            let output_prefix = format!(
                "{}{}",
                child_prefix,
                Connector::Last.child_prefix()
            );

            display_ast(
                arena,
                body,
                output_prefix,
                Connector::Last,
                "".to_string(),
                descriptions,
            );
        }
        Expression::Empty => {
            descriptions.push(format!(
                "{}{}{} {}",
                prefix,
                connector.display(),
                extra.cyan(),
                "Empty".purple(),
            ));
        }
    }
}
