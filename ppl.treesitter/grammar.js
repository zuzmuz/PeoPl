/**
 * @file the peopl's language
 * @author zuzmuz <hamadeh0@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
//
const PREC = {
  ACCESS: 30,
  PARAM: 20,
  TYPES: 15,
  UNARY: 10,
  MULT: 8,
  ADD: 6,
  COMP: 5,
  AND: 4,
  OR: 3,
  PIPE: 2,
  SUBPIPE: 1,
};

module.exports = grammar({
  name: "peopl",

  extras: $ => [
    $.comment, /\s|\\\r?\n/,
  ],

  rules: {
    source_file: $ => repeat(
      seq(
        $.field,
      )
    ),

    comment: _ => token(
      choice(
        seq('//', /(\\+(.|\r?\n)|[^\\\n])*/),
        seq(
          '/*',
          /[^*]*\*+([^/*][^*]*\*+)*/,
          '/',
        ),
      ),
    ),

    // DEFINITIONS
    // -----------
     
    identifier: $ => /[A-Za-z_][A-Za-z-0-9_]*/,

    field: $ => seq(
      field("name", $.identifier),
      ":",
      field("definition", $.expression),
    ),

    field_list: $ => seq(
      seq(
        choice(
          $.field,
          $.expression
        ),
        repeat(seq(
          ',',
          choice(
            $.field,
            $.expression
          )
        )),
        optional(',')
      ),
    ),

    squared_field_list: $ => seq(
      '[',
        optional($.field_list),
      ']',
    ),

    // Expression
    // ----------

    expression: $ => choice(
      $._simple_expression,
      $.function_definition,
      $.branched_expression,
      $.piped_expression
    ),

    call_expression: $ => seq(
      field("prefix", $._simple_expression),
      field("arguments", $.squared_field_list),
    ),

    // Function Definitions
    // --------------------
    
    function_definition: $ => prec.left(seq(
      field("signature", $.function_signature),
      field("body", optional($.function_body)),
    )),

    function_signature: $ => seq(
      $.func,
      optional(seq('(', field("input_type", $.expression), ')')),
      optional(field('arguments', $.squared_field_list)),
      optional(seq('->', field("output_type", $.expression))),
    ),

    function_body: $ => seq(
      '{',
        $.expression,
      '}'
    ),

    nothing: _ => 'nothing',
    never: _ => 'never',
    tuple: _ => 'tuple',
    record: _ => 'record',
    union: _ => 'union',
    choice: _ => 'choice',
    func: _ => 'func',

    special: $ => choice(
      $.nothing,
      $.never,
      $.tuple,
      $.record,
      $.union,
      $.choice,
    ),

    literal: $ => choice(
      $.int_literal,
      $.float_literal,
      $.string_literal,
      $.bool_literal,
    ),

    _simple_expression: $ => choice(
      $.special,
      $.literal,
      $.unary_expression,
      $.binary_expression,
      $.squared_field_list,
      $.identifier,
      $.parenthisized_expression,
      $.function_body,
      $.call_expression,
      $.access_expression,
      $.binding
    ),

    parenthisized_expression: $ => seq(
      '(',
      $.expression,
      ')',
    ),

    access_expression: $ => seq(
      field("prefix", $._simple_expression),
      '.',
      field("field", $.identifier),
    ),

    binding: $ => seq('$', $.identifier),

    // Literals
    // --------
    
    int_literal: $ => token(choice(
        /[0-9][0-9_]*/,
        /0x[0-9a-fA-F_]+/,
        /0b[01_]+/,
        /0o[0-7_]+/,
    )),

    float_literal: $ => /\d+\.\d+/,
    string_literal: $ => /"[^"]*"/,
    bool_literal: $ => choice('true', 'false'),

    // Operators
    // ---------

    // a unary operator followed by a simple expression 
    unary_expression: $ => prec.left(PREC.UNARY,
      seq(
        field("operator", choice(
          $.multiplicative_operator,
          $.additive_operator,
          $.comparative_operator,
          $.and_operator,
          $.or_operator,
          $.not_operator,
        )),
        field("operand", $._simple_expression),
      )
    ),
    // two simple expressions surrounding a arithmetic or logic operator
    binary_expression: $ => choice(
      prec.left(PREC.MULT,
        seq(
          field("left", $._simple_expression),
          field("operator", $.multiplicative_operator),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.ADD,
        seq(
          field("left", $._simple_expression),
          field("operator", $.additive_operator),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.COMP,
        seq(
          field("left", $._simple_expression),
          field("operator", $.comparative_operator),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.AND,
        seq(
          field("left", $._simple_expression),
          field("operator", $.and_operator),
          field("right", $._simple_expression),
        )
      ),
      prec.left(PREC.OR,
        seq(
          field("left", $._simple_expression),
          field("operator", $.or_operator),
          field("right", $._simple_expression),
        )
      )
    ),

    multiplicative_operator: $ => choice('*', '/', '%'),
    additive_operator: $ => choice('+', '-'),
    comparative_operator: $ => choice('=', '!=', '>', '>=', '<', '<='),
    not_operator: $ => 'not',
    and_operator: $ => 'and',
    or_operator: $ => 'or',

    branched_expression: $ => prec.left(PREC.SUBPIPE, seq(
      $.branch,
      repeat(seq(',', $.branch)),
    )),

    branch: $ => seq(
      '|', 
      field("match_expression", $._simple_expression),
      optional(seq(':', field("guard_expression", $._simple_expression))),
      '|',
      field("body", choice(
        $._simple_expression,
        $.looped_expression,
      ))
    ),

    looped_expression: $ => seq(
      $.parenthisized_expression,
      '^'
    ),

    piped_expression: $ => prec.left(PREC.PIPE, seq(
        field("left", $.expression),
        field("operator", $.pipe_operator),
        field("right", $.expression),
    )),

    pipe_operator: $ => '|>',
  }
});
