mod syntax;
use crate::syntax::{parser, tokenizer};

fn main() {
    let test_string = "3\n10\n12,0xff, 0b100, hi, \"string\"";

    let mut parser = parser::Parser::new(test_string);

    let ast = parser.parse();

    ast.expression_list
        .iter()
        .for_each(|&idx| println!("{:?}", &parser.expressions[idx]))
}
