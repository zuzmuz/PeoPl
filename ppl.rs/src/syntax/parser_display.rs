use crate::syntax::parser::{self, Expression};
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

pub trait ASTDisplay {
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
            Expression::Positional(_) => todo!(),
            Expression::Binding(_) => todo!(),
            Expression::Unary(operator, expression) => {
                descriptions.push(format!(
                    "{}{}{} {}",
                    prefix,
                    connector.display(),
                    extra.cyan(),
                    operator.to_string().bright_red()
                ));

                expression.display_ast(
                    child_prefix,
                    Connector::Last,
                    "expr: ".to_string(),
                    descriptions,
                )
            }
            Expression::Binary(operator, lhs, rhs) => {
                descriptions.push(format!(
                    "{}{}{}{}",
                    prefix,
                    connector.display(),
                    extra.cyan(),
                    operator.to_string().bright_red()
                ));

                lhs.display_ast(
                    child_prefix.clone(),
                    Connector::NotLast,
                    "lhs: ".to_string(),
                    descriptions,
                );
                rhs.display_ast(
                    child_prefix,
                    Connector::Last,
                    "rhs: ".to_string(),
                    descriptions,
                );
            }
            Expression::List(container, expressions) => {
                descriptions.push(format!(
                    "{}{}{}{} {}",
                    prefix,
                    connector.display(),
                    extra.cyan(),
                    "List -".yellow(),
                    container.to_string().blue()
                ));
                for (index, expression) in expressions.iter().enumerate() {
                    let is_last_arg = index == expressions.len() - 1;
                    expression.display_ast(
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
                descriptions.push(format!(
                    "{}{}{}{} {}",
                    prefix,
                    connector.display(),
                    extra.cyan(),
                    "Call -".red(),
                    container.to_string().blue()
                ));

                prefix_expr.display_ast(
                    child_prefix.clone(),
                    Connector::NotLast,
                    "prefix: ".to_string(),
                    descriptions,
                );

                for (index, expression) in fields.iter().enumerate() {
                    let is_last_arg = index == fields.len() - 1;
                    expression.display_ast(
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
            Expression::Access(expression, identifier) => {
                descriptions.push(format!(
                    "{}{}{}{} {}",
                    prefix,
                    connector.display(),
                    extra.cyan(),
                    "Access -".red(),
                    identifier.0.to_string().blue()
                ));

                expression.display_ast(
                    child_prefix,
                    Connector::Last,
                    "prefix: ".to_string(),
                    descriptions,
                );
            }
            Expression::Tagged(identifier, expression) => {
                descriptions.push(format!(
                    "{}{}{}{} {}",
                    prefix,
                    connector.display(),
                    extra.cyan(),
                    "Tagged -".red(),
                    identifier.0.to_string().blue()
                ));

                expression.display_ast(
                    child_prefix,
                    Connector::Last,
                    "expr: ".to_string(),
                    descriptions,
                );
            }
            Expression::Branched(branches) => {
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

                    branch.match_expression.display_ast(
                        format!(
                            "{}{}",
                            child_prefix,
                            branch_connector.child_prefix()
                        ),
                        Connector::NotLast,
                        "match: ".to_string(),
                        descriptions,
                    );

                    if let Some(guard_expression) = &branch.guard_expression {
                        guard_expression.display_ast(
                            format!(
                                "{}{}",
                                child_prefix,
                                branch_connector.child_prefix()
                            ),
                            Connector::NotLast,
                            "guard: ".to_string(),
                            descriptions,
                        );
                    }

                    descriptions.push(format!(
                        "{}{}{}{}",
                        child_prefix,
                        branch_connector.child_prefix(),
                        Connector::Last.display(),
                        "Body".red(),
                    ));

                    branch.body.display_ast(
                        format!(
                            "{}{}{}",
                            child_prefix,
                            branch_connector.child_prefix(),
                            Connector::Last.child_prefix()
                        ),
                        Connector::Last,
                        "".to_string(),
                        descriptions,
                    );
                }
            }
            Expression::Function(args, body) => {
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

                for (index, expression) in args.iter().enumerate() {
                    let is_last_arg = index == args.len() - 1;
                    expression.display_ast(
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

                body.display_ast(
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
}
