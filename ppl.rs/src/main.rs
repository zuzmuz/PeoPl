mod syntax;
use crate::syntax::tokenizer;

fn main() {
    let test_string = "  12 0x8f  0b10_10_01_00   0o123_456 ";
    tokenizer::lex_source(test_string);
}
